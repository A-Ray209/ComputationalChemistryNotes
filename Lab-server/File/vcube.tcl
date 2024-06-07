if 0 {
    VCUBE Version 3.0
    update date: 2022-02-25
	Feature: High throughput cube render using vmd; High quality image; 
    made by Zhong Cheng; QQ:32589927, E-mail:ggdhzdx@qq.comment
	Feel free to contact me if you have any suggestions or find bugs  
}

package provide vcube 3.0
# todo list
# a bug if I delele a molecule manually
# cube file with multicube
# vstyle to specific (local & global)
# set default style
# atom color and style
# periodic support
# vrender with animation
# vrender -obj to export obj for powerpoint   Done!!
# add more cube style
# a bug build movie in windows
# vapply could argument to script
# put tutorial.md in scripts and styles
# map the arrow keys to atoms style change
# fix  bug for add bonds in metal (too many bonds)
# vhighlight
# regret : vmd do not have 
# build test set 
# add type option to viso function
# varrow 2D arrow
# todo  add Home key to reset view
#  add arrow key to 

puts "vcube loaded..."
puts "vcube version 3.0 developed by ZhongCheng@whu.edu.cn"
puts {type "vhelp" to get list of available functions and keyboard shortcuts}
puts {type "vhelp function" to get detailed usage of that function}

namespace eval ::vcube {
    namespace export vcube vmol vc vshowalways vgroup vreset vrender vrenders vrenderf vrename vmscale vmeasure vcscale viso varrow vapply valpha vstyle vlabel vbond vhelp vsc vtachyopt Vnav_mol Vnav_iso Vnav_alpha Vnav_cscale Vnav_mscale Vglobal_switch 
    global env
    global style_dir
	global vcube_script_dir 
    global image_viewer
    global optix
    global ospray
    global imagemagick
    global nproc 
    global compose   
    # wether compose graphic object on top of molecule
    variable label_color black
    variable measure_color [dict create b blue a blue d blue]
    variable label_size 1.5
    variable label_thick 3
    set ::compose ""
    set ::nproc 100
    set ::image_viewer "eog gwenview" 
    # check if TachyonInternal is available
    if {[lsearch [render list] TachyonLOptiXInternal] >= 0} {
        puts "TachyonLOptiXInternal is available. Turn it on by input \"set optix 1\""
        set ::optix 0
    } else { set ::optix 0 }
    if {[lsearch [render list] TachyonLOSPRayInternal] >= 0} {
        puts "TachyonLOSPRayInternal is available. Turn it on by input \"set ospray 1\""
        set ::ospray 0
    } else { set ::ospray 0}
    # check is imagemagick is available
    set imexe [auto_execok mogrify]
    if {$imexe != ""} {
        set impath [file join {*}[lrange [file split $imexe] 0 end-1]]
        puts "imagemagick found in $impath, following functions available:"
        variable composite_com composite 
        variable convert_com [file join $impath convert]
    } else {
        set imexe [auto_execok magick.exe]
        if {$imexe != ""} {
            puts "imagemagick found in $imexe, following functions available:"
            variable composite_com "magick.exe composite"
            variable convert_com "magick.exe convert"
            variable mogrify_com "magick.exe mogrify"
        } elseif {[catch {exec [auto_execok wsl] which mogrify}] == 0} {
            puts "imagemagick found in WSL, follwing functions available"
            variable composite_com "wsl composite"
            variable convert_com "wsl convert"
            variable mogrify_com "wsl mogrify"
        } else {
            puts "imagemagick not found, following functions not available:"
            variable composite_com "compostie"
            variable convert_com "convert"
            variable mogrify_com "mogrify"
        }
    }
    puts "    vrenderf/vrender could generate gif using $composite_com"
    puts "    vrender will auto convert bmp to png and can do trimming using $mogrify_com"
    puts "    labels or measurements will be composited on top of the molecule using $composite_com"
    # check if ffmpeg is available
    set ffmpeg_exe [auto_execok ffmpeg] 
    if {$ffmpeg_exe != ""} {
        variable ffmpeg_com ffmpeg 
        puts "ffmpeg found in $ffmpeg_exe, vrenderf/vrender could generate mp4 using $ffmpeg_com"
    } else {
        if {[catch {exec [auto_execok wsl] which ffmpeg}] == 0} {
            variable ffmpeg_com "wsl ffmpeg"
            puts "ffmpeg found in WSL, vrenderf/vrender could generate mp4 using $ffmpeg_com"
        } else {
            variable ffmpeg_com "ffmpeg"
            puts "ffmpeg not found, vrenderf/vrender could not generate mp4"
        }
    }
    variable global_adj 1
    variable show_switch 0 # "0 show top; 1 show group; 2 show all"
    variable tachyon_options ""
    variable tachyon_defaults "-format BMP -aasamples 24 "
	variable tachyon_user ""
    variable current_style ""
    variable suface_type ""  # normal or map
    variable show_always ""  # molids that always display, set by vshowalways function by user
    variable separator "-"
    variable groupbyidx {end-1} # group by list elements generate by separator, -1 mean not last elements
    variable grouplist ""      # grouplist generate by vgroup using separator
    variable map_scale_value {-0.03 0.03} # default scale for map cube
	variable color_scale BWR   #default color scale for map cube
}
proc ::vcube::vhelp {args} {
    if {$args eq ""} {
        puts {vcube version 3.0, use "vh commmand" to check the detail usage of that command}
        puts {vcube [map] cubefilename           : input cubefiles to render}
        puts {vmol filename                      : load only molecules}
        puts {vc molid                           : display and free target molecule }
        puts {viso iso1 iso2 molids              : set iso value for molids}
        puts {valpha alpha_value molids          : set alpha(transparency) for molids}
        puts {vstyle stylename molids            : apply cube style to molids}
        puts {vastyle stylename molids           : apply atom style to molids}
        puts {vmscale min max molids             : set min and max map scale to molids}
		puts {vcscale min max molids             : set color scale}
        puts {vrender -suf "_x" -s 3             : render all with scale 3x and append filename by "_x"}
        puts {vrenders -n "filename" -s 3        : render current scene with scale}
        puts {vrenderf -b 0 -e 100 -step 1       : render frames from 1 to 100 continuously}
        puts {vbond add "Ag Au" "S" 3.0          : add bond Ag-S and Au-S if distance between them is less than 3.0}
		puts {vlabel                             : set labels for molecules}
		puts {vhighlight                         : select and highlight atoms }
		puts {vmeasure                           : do measurements and label the measure results }
        puts {vgroup string                      : set the file name separator or molids to group mol}
		puts {vapply scriptfile molids           : apply vmd script file to molids}
        puts {vshowalways molids                 : set the target molid to show always}
        puts {vreset                             : reset all molecules}
		puts {vtachyopt                          : set tachyon options}
		puts {varrow x y z -cc blue              : draw an blue arrows from origin to xyz}
        puts {vrename str1 str2 molid            : substitude str1 by str2 for names of molid, support regexp}
        puts {command -h                         : show detailed usage of specifed function}
        puts {-----------------------------------------------------------------------------------}
        puts {keyboard shortcut: }
        puts {a d        : previous or next molecule}
        puts {w s        : previous or next molecule with same group unfreeze together}
        puts {q e        : decrease or increase iso}
        puts {Pgup Pgdn  : previous or next style}
        puts {v          : render current scene for preview}
        puts {g          : switch between display single/group/all molecules}
		puts {Ins Del    : previous or next color scale}
		puts {left up    : decrease or increase min value of mapped value}
		puts {down right : decrease or increase max value of mapped value}
        puts {f          : adjust iso or alpha with shortcut local or global}
        puts {-----------------------------------------------------------------------------------}
        puts {variables: (usage example: "set nproc 10" "set image_viewer gwenview") }
        puts {nproc        :max number of threads used by tachyon, default is the number of cores minus 2}
        puts {image_viewer :set program to preview image in Linux, default is eog and gwenview }
        puts {optix        :If set to 1, will use TachyonLOptiXInternal to render image, default is 0 }
        puts {ospray       :If set to 1, will use TachyonLOSPRayInternal to render image, default is 0 }
        puts {compose      :set compose method for arrow, default is Multiply, common avail: Screen,Overla,Over,blend:70,dissolve:30}
        puts {             :blend:70 will merge 70% of graph to molecule, dissovle:0 is complete transparent and 100 is equal to Over}
    }
    if {$args eq "viso"} {
        puts {viso iso1 iso2 -id molids   : set iso value for molids}
        puts {viso                        : list iso value for all the molecules}
        puts {viso 0.02 -0.02             : set iso value for all the molecules}
        puts {viso -r                     : reverse orbital phase}
        puts {viso 1000 1000              : remove surface}
        puts {viso 0.01 -0.01 -id "1-3 5" : set iso value for molecule 1-3 and 5} 
        puts {viso -t orb                 : use the default iso value for orbital type cube} 
        viso -t list
    }
    if {$args eq "vstyle"} {
        puts {vstyle stylename molids      : apply style to molids}
        puts {vstyle                       : list all the available style and show corresponding comments}
        puts {vstyle sob-art.stl           : apply sob-art.stl style to all molecules} 
        puts {vstyle sob-art.stl -id "4-8" : apply sob-art.stl style to molecules 4-8} 
        puts {vstyle sob-esp0.mstl         : apply sob-esp0.mstl mapped style to all molecules} 
    }
    if {$args eq "vcube"} {
        puts {vcube [map] cubefilename                   : input cubefiles to render}
        puts {vcube *.cube                               : render all cube file in current directory}
        puts {vcube a1_oH.cub a1_oL.cub a1_oH1.cub       : render three cube file }
        puts {vcube map 1_d.cub 1_e.cub 2_d.cub 2_e.cube : map a1_e.cub a2-e.cub to a1_d.cub and 2a_d.cube, respectively}
        puts {vcube map *.cub                            : same as above, because *e.cub fill will after *d.cub}
        puts {vcube *d.cub map *e.cub                    : same as above, cub in *e.cub will map to cub in *d.cub one by one}
    }
    if {$args eq "vmol"} {
        puts {vmol filename      : load files as molecules, available type: https://www.ks.uiuc.edu/Research/vmd/plugins/molfile/}
        puts {vmol *.pdb         : read all pdb file, the filetype will be determined by filename suffix}
        puts {vmol *.cub         : read all cube files, but the surface will not shown}
        puts {vmol traj.xyz first 100 last 200 step 1 : read traj.xyz start from frame 100 to frame 200 with no separation between frames }
    }
    if {$args eq "vc"} {
        puts {vc molid                    : unfreeze and make top target molecule}
        puts {vc                          : unfreeze all the mol and make the last one top}
        puts {vc 0                        : unfreeze mol id 0 and make it top }
        puts {vc "0-2 4"                  : unfreeze mol id 0 1 2 4 and make 4 top }
        puts {The unfreeze molecules are not necessarily displayed,}
        puts {the keyboard shortcut g controls how molecules are displayed }
    }
    if {$args eq "vgroup"} {
        puts {vgroup string       : set the file name separator to group files, if string is one elem }
        puts {vgroup              : view current separator and file groups}
        puts {vgroup _            : file a1_oH.cub and a1_oL.cub will be in the same group} 
        puts {vgroup _e           : file a1_e1.cub and a1_o1.cub will be in the different group}
        puts {vgroup {- 2}        : sep by - and use 0 to 2 elements to group: a-1-e-1.cub and a-1-o-1.cub in different group}
        puts {vgroup {- -1}       : sep by - and use elements other than 0 to 1 to group: a-1-e-1.cub and a-2-e-1.cub in same group}
       	puts {vgroup by 1,2 4,5   : molid 1,2 in one group 4,5 in another group }
    }
    if {$args eq "vmscale"} {
        puts {vmscale min max molids      : set min and max map scale to molids}
        puts {vmscale                     : view current map scale}
        puts {vmscale -0.02 0.02          : set map scale to -0.02 0.02 for all}
        puts {vmscale -0.02 0.02 top      : set map scale to -0.02 0.02 for the top molecule}
        puts {vmscale -0.02 0.02 "1 2"    : set map scale to -0.02 0.02 for molid 1 2}
    }
	
	if {$args eq "vcscale"} {
        puts {vcscale color_scale_name    : set color scale for all molids}
        puts {vcscale                     : view current color scale and available color scale}
        puts {vcscale BWR                 : set color scale to BWR for all}
    }
    
    if {$args eq "valpha"} {
        puts {valpha alpha_value molids   : set alpha(transparency) for molids}
        puts {valpha                      : view current alpha value}
        puts {valpha 0.6                  : set alpha to 0.6 for all molecule}
        puts {valpha 0.5 -id "0-2 4"      : set alpha to 0.5 for molid 0 1 2 4}
    }
    if {$args eq "vreset"} {
        puts {vreset        : reset all to the initial conditions }
        puts {The show_always will be cleaned}
    }
	if {$args eq "vrender"} {
        puts {vrender                   : render all with 3 fold scale }
        puts {vrender -id "1-3 7"       : render id 1 2 3 7 with scale 3}
        puts {vrender -s 4              : render all with 4 fold scale }
		puts {vrender -suf "_topview"   : output filename is appended by "_topview"}
		puts {vrender -ani mp4 -id 1-10 : use mol id 1 to 10 to build a mp4 movie, an other available format is gif }
		puts {vrender -fps 12           : set the fps to 12 for the animation}
		puts {vrender -obj              : render Wavefront obj for using in Powerpoint/Word 2019}
    }
	if {$args eq "vrenders"} {
        puts {vrenders                : render current scene to "current.bmp" with 3 fold scale}
        puts {vrenders -n "abc" -s 2  : render current scene with scale 2 and filename "abc.bmp"}
    }
	if {$args eq "vrenderf"} {
        puts {vrenderf -b -100                  : set the begin frame 100 from the last, default 1}
        puts {vrenderf -e 1000                  : set the last frame the 1000th frame, default -1 }
        puts {vrenderf -step 2                  : set the interval between frames 1, default 1}
        puts {vrenderf -s 2                     : render all frames of top mol with 2 fold scale, default 2}
        puts {vrenderf -id 1-3                  : render all frames for mol id 1 2 3, default top}
        puts {vrenderf -fps 30                  : set fps to estimate time of movie, default 30}
        puts {vrenderf -ani gif                 : set movie format to gif, default mp4}
    }
	if {$args eq "vrename"} {
        puts {vrename str1 str2 molids     : replace str1 by str2 for names for molids, str1 could be regexp }
        puts {vrename oH HOMO              : replace oH by HOMO for all molecule names}
        puts {vrename {^} view1_  1 2 3    : add prefix view1_ to molecule 1 2 3}
        puts {vrename {\d} ""              : remove first encountered digits of all mol name}
        puts {vrename {\d+} ""             : remove first encountered consecutive digits of all mol name}
        puts {vrename {\..*} ""            : remove file name suffix (e.g. cub) of all mol name}
        puts {vrename {.cub} _side.cub     : append suffix _side to all mol name}
    }
	if {$args eq "varrow"} {
        puts {varrow 0.5 1.0 2                 : draw arrow from origin to 0.5 1.0 2 }
        puts {varrow 1 1 1 -o 2 2 2            : origin, draw arrow from 2 2 2 to 3 3 3. default origin is 0 0 0 }
        puts {varrow 2 2 2 -p 0                : positon of origin on arrow, 0 is start (default). 0.5 is mid. 1 is end}
        puts {varrow x y z -s 1                : scale the length of arrow, default 1 }
        puts {varrow x y z -r 0.1              : radius of cylinder, default 0.1 }
        puts {varrow x y z -c red              : color name or id of arrow }
        puts {varrow 1 1 1 -b 2 2 2            : begin, draw arrow from 2 2 2 to 1 1 1 }
        puts {varrow x y z -id 0               : which molid to draw arrow, default is top }
        puts {varrow x y z -id "1 3-6"         : multiple molid should be separated by space and in double quotes }
        puts {varrow x y z -mat transparent    : material, default do not use material}
        puts {varrow x y z -res 30             : resolution, default 30 }
        puts {varrow x y z -cs 0.2             : cone size, default is 0.2}
        puts {varrow x y z -cr 1               : core ratio, the length to width ratio of cone, default is 1 }
        puts {varrow x y z -double             : draw double head arrow }
        puts {varrow del                       : delete all arrows in current molid }
        puts {varrow del -id all               : delete all arrows in all molid }
        puts {set compose dissolve:70          : make the arrow 30% tranpsarent and put on top of the molecule. vhelp to see more usage of compose}
        puts {set compose Multiply             : put the arrow on top of the molecule and set blend mode to Multiply.}
    }
	if {$args eq "vlabel"} {
        puts {vlabel                 : draw index label for the top molecule}
        puts {vlabel -c black        : set label color to black}
        puts {vlabel -s 2 -t 2       : set label font size and thickness}
        puts {vlabel -id "1-3 5"     : draw index label for molecules 1 2 3 5}
        puts {vlabel -id all         : draw index label for all molecules}
        puts {vlabel del             : delete all labels}
        puts {vlabel -sel "all"      : set atom selection to specify which atoms to label, e.g. }
        puts {                       : sel "not name \"H.*\"" label non hydrogen atoms}
        puts {                       : sel "atomicnumber 7 8" label all Oxygen and Nitrogen}
        puts {                       : sel "serial 2 to 8 10 and element C" label carbon with serial 2 to 8 10}
        puts {                       : for more selection syntax goto "http://sobereva.com/504"}
        puts {vlabel -type "%1i"     : set the type of label, e.g. }
        puts {                       : "%1i-%e" atom index followed by element like "2-H"}
        puts {                       : "%a:%q:%t" atom name and charge and type separated by ":"}
        puts {                       : "%d%1R" resid followed by resname like "2LYS" }
        puts {vlabel -f " "          : use contents in file to label atom,} 
        puts {                       : the file has one column and rows equal to number of atom}
    }
	if {$args eq "vmeasure"} {
        puts {vmeasure                         : show this help}
        puts {vmeasure B 1 3 B 1 4             : measure distance between atom 1 and 3 and atoms 1 and 4}
        puts {vmeasure MB "3,5-8 Au" S 2 3     : measure distance between "3,5-8 Au" and S if their distances > 2A and < 3A}
        puts {vmeasure A 1 3 2                 : measure angle 1 3 2}
        puts {vmeasure D 1 3 2 4               : measure dihedral 1 3 2 4}
        puts {vmeasure -c bond black           : set color of bond measure to black}
        puts {vmeasure -c dihedral red         : set color of dihedral measure to red}
        puts {vmeasure -s 1.5                  : set size of dihedral measurement to 1.5}
        puts {vmeasure -t 3                    : set thickness of spring measurement to 3}
        puts {vmeasure del                     : delete all measurements}
        puts {notes: 1. vmeasure thick size and color will apply to all label in all molid}
        puts {       2. zoom by mouse wheel or scale mode (S) will not change size and thick but zoom by screen Hgt will}
        puts {       3. offset of label do not have any effect when render with tachyon}
        puts {       4. install imagemagick to avoid measurement been convered by atom}
        puts {       5. vmeasure MB O H 1.3 2.6 size 0.0001 thick 0.0001 will show hydrogen bond}
    }
	if {$args eq "vbond"} {
        puts {vbond                          : show this help}
        puts {vbond reset                    : run "mol bondsrecalc all; topo retypebonds" commands to reset bonding}
        puts {vbond -a "Fe Co" "C N" 3.0     : add bond Fe-C Fe-N Co-C Co-N if their distance smaller than 3.0 A}
        puts {vbond -a "1,3-5 Au" S 3.0      : could use both atom seiral (start from 1) and element to define set}
        puts {vbond -a Pb S 3.0 -id all      : add bond between Pb-S for all mols, default only deal with top mol}
        puts {vbond -d Ni Ni 2.5             : delete bond Ni-Ni if their distance larger than 2.5 A}
        puts {vbond reset -t on              : rebuild bonds for each frame}
        puts {vbond reset -a Fe N 3 -t on    : rebuild bonds and add bond for Fe-N for each frame}
        puts {vbond -t off                : stop modify bond for each frame}
        puts {tips:  1. If system have 5 Fe and 100 N, then should use "vbond add Fe N 2" rather than "vbond add N Fe 2" }
        puts {       2. With trace on the animate in vmd is slow. You could use vrenderf to generate movie }
        puts {       3. trace on will automatic turn off id all}
    }
	if {$args eq "vapply"} {
		puts {vapply                          : list all scripts file ends with .vmd or .tcl}
        puts {vapply script_file -id molids   : apply user writen script file to molids}
        puts {vapply script_file              : apply script file to all molids}
		puts {vapply script_file -arg "2 4"   : apply script_file to all molids and pass "2 4" to the vapply_args variable in the script}
        puts {notes: 1. the molid in script file should be top}
        puts {       2. use "File --> Log Tcl Commands to Console" to find corresponding commands of an operation}
        puts {       3. the file name should be end with .vmd or .tcl}
        puts {       4. the file should be in the working dir or dir defined by vcube_script_dir variable in vmd.rc}
        puts {       5. vapply_args variables in the script could accept values followed by -arg}
    }
    if {$args eq "vshowalways"} {
        puts {vshowalways molids          : set the target molid to show always}
        puts {vshowalways                 : cancel showalways molecule}
        puts {vshowalways "1 2"           : set molid 1 2 to show always and unset other molid}
    }
	if {$args eq "vtachyopt"} {
        puts {vtachyopt                   : show the current used tachyon option and other available options }
        puts {vtachyopt " "               : use default tachyon options}
		puts {vtachyopt "-trans_orig"     : use this tachyon options that suitable for small alpha surface}
		puts {vtachyopt "-numthreads 8"   : set numthreads for tachyon}
    }
}


#######################################################################################################################
# helper function
#######################################################################################################################
proc ::vcube::parsesel {args} {
    # convert selection to atom index
    # like "c hg 1,3-15 5"
    set idxlist ""
    set args [string map {\{ {} \} {}} $args]
    set args [regexp -inline -all -- {\S+} $args]
    if {$args eq "all"} {
       set idxlist [[atomselect top all] list]
    } else {
        foreach var $args {
            if {[regexp {^[a-zA-Z]{1,2}$} $var]} {
                set var [string totitle $var]
                set idxlist [concat $idxlist [[atomselect top "element $var"] list ]]
            }
            if {[regexp {^[0-9,-]+$} $var]} {
                set var [string totitle $var]
                set var [string map {, " "} $var]
                foreach i $var {
                    if {[string first "-" $i] != -1} {
                        set begin [lindex [split $i -] 0]
                        set end [lindex [split $i -] 1]
                        for {set N $begin} {$N <= $end} {incr N} {
                            lappend idxlist [expr $N - 1]
                        }
                    } elseif {[string is integer $i]} {
                        lappend idxlist [expr $i - 1]
                    } 
                }
            }
        }
    }
    if {[llength $idxlist] > 0} {
        set idxlist [[atomselect top "index $idxlist"] list]
    }
    return $idxlist
}

proc ::vcube::parseid {args} {
    set idlist ""
    set args [string map {, " "} $args]
    set args [string map {\{ {} \} {}} $args]
    set args [regexp -inline -all -- {\S+} $args]
    if {$args eq "all"} {
       set idlist [molinfo list]
    } elseif {$args eq "top"} {
        set idlist [molinfo top]
    } elseif {[llength $args] > 1} {
        foreach molid $args {
            if {[string first "-" $molid] != -1} {
                set begin [lindex [split $molid -] 0]
                set end [lindex [split $molid -] 1]
                for {set N $begin} {$N <= $end} {incr N} {
                    lappend idlist $N
                }
            } elseif {[string is integer $molid]} {
                lappend idlist $molid
            } 
        }
    } elseif {[string is integer $args]} {
        set idlist $args
    } elseif {[string first "-" $args] != -1} {
        set begin [lindex [split $args -] 0]
        set end [lindex [split $args -] 1]
        for {set N $begin} {$N <= $end} {incr N} {
            lappend idlist $N
        }
    }
    return $idlist
}

proc ::vcube::switch_rep {args} {
    # turn off all rep or turn them on depends on if args is 0 or 1
    set mollist [molinfo list]
    foreach molid $mollist {
        if {[molinfo $molid get drawn] == 1} {
            lappend mol_on $molid
            for {set i 0} {$i < [molinfo top get numreps]} {incr i} {
                mol showrep $molid $i $args
            }
        }
    }
}

# guess isovalue based on cubefile name
proc ::vcube::Vautoiso {cubename {sign p}} {
    variable separator
    array set defisop {esd 0.001 orb 0.025 den 0.001 elf 0.01 lol 0.01 ele 0.001 hole -0.001 igmh 0.005 igm 0.01 igmhp 0.005 igmp 0.01 iri 1.0 rdg 0.5 rdgp 0.5}
    array set defisom {esd -0.001 orb -0.025 den -0.001 elf -0.01 lol -0.01 rdg 0.5 ele -0.001 hole 0.001 igmh 0.005 igmhp 0.005 igm 0.01 igmp 0.01 iri 1.0 rdg 0.5 rdgp 0.5}
    set basename [file rootname $cubename]
    set cubetype [lindex [split $basename $separator] end]
    # set cubetype [string range $cubetype end-2 end]
    if {[string match {o[HL]*} $cubetype] > 0 } {
        set cubetype orb
    }
    if {![info exists defisop($cubetype)]} {
        if {$sign == "p"} { 
            return 0.01
        } elseif {$sign == "m"} {
            return -0.01
        }
    }
    if {$sign == "p"} {
        return $defisop($cubetype) 
    } elseif {$sign == "m"} {
        return $defisom($cubetype)
    }
}

proc ::vcube::Vautomap {cubename} {
    variable separator
	variable map_scale_value
	variable color_scale
    array set defcscale {esp BWR lmd RGB}
    array set defmscale {esp {-0.03 0.03} lmd {-0.04 0.02}} 
    set basename [file rootname $cubename]
    set cubetype [lindex [split $basename $separator] end]
    set cubetype [string range $cubetype end-2 end]
    if {![info exists defcscale($cubetype)]} {
        set color_scale BWR
    } else {
	    set color_scale $defcscale($cubetype)
	}
	if {![info exists defmscale($cubetype)]} {
        set map_scale_value {-0.03 0.03}
    } else {
	    set map_scale_value $defmscale($cubetype)
    }
}

proc ::vcube::Vfree_mol {idxlist} {
    foreach i $idxlist {mol free $i} 
}

proc ::vcube::getname {args} {
    # get basename for mol id in args
    set basenames ""
	foreach i $args {
        vc $i
        set originfile [string trim [molinfo $i get name] \}\{  ]
        if {[llength $originfile] == 1} {
            set basename [file rootname $originfile]
        } else {
            set basename [file rootname [lindex $originfile end]]
        }
        lappend basenames $basename
    }
    return $basenames
}

proc ::vcube::Vcalc_delta {isov {delta 1}} {
    set isov01 [expr $isov / 10]
    set isov01 [string trimright [format %.10f $isov01] 0]
    if {abs($isov01) < 1} {
        set iso0 [string trimright $isov01 123456789]
        set isod ${iso0}$delta
    } elseif {abs($isov01) >= 1} {
        set isod [expr $dalta*10**floor(log10($isov01))]
    }
	set isod [string trimright [format %.8f $isod] 0]
    return $isod
}

proc ::vcube::Vnthread {} {
    global nproc
    set ncores [numberOfCPUs]
    set nthread [expr $ncores / 2 -2]
    if {$nthread < 1} {set nthread 1}
    if {$nthread > $nproc} {set nthread $nproc}
    return $nthread
}

proc ::vcube::numberOfCPUs {} {
    # Windows puts it in an environment variable
    global tcl_platform env
    if {$tcl_platform(platform) eq "windows"} {return $env(NUMBER_OF_PROCESSORS)}
    # Check for sysctl (OSX, BSD)
    set sysctl [auto_execok "sysctl"]
    if {[llength $sysctl]} {
        if {![catch {exec {*}$sysctl -n "hw.ncpu"} cores]} {return $cores}
    }
    # Assume Linux, which has /proc/cpuinfo, but be careful
    if {![catch {open "/proc/cpuinfo"} f]} {
        set cores [regexp -all -line {^processor\s} [read $f]]
        close $f
        if {$cores > 0} {return $cores}
    }
    # No idea what the actual number of cores is; exhausted all our options
    # Fall back to returning 1; there must be at least that because we're running on it!
    return 1
}


#######################################################################################################################
# user available load and mol manage function
#######################################################################################################################

proc ::vcube::vcube {args} {
    # args are list of cube files
    # to render mapped cube, the format of args could be 
    # map dens1 map1 dens2 map2... or
    # dens1 dens2... map map1 map2...
    variable surface_type
     if {[lsearch $args map] == -1} {
        set surface_type norm
        set basecubes [glob {*}$args]
        set mapcubes ""
    }
    if {[lsearch $args map] == 0} {
        set surface_type map
        set basecubes ""
        set mapcubes ""
        puts [glob {*}$args]
        foreach {a b} [lsort [glob {*}$args]] {
            lappend basecubes $a
            lappend mapcubes $b
        }
    }
    if {[lsearch $args map] > 0} {
        set surface_type map
        set x [lsearch $args map]
        set basecubes [lsort [glob {*}[lrange $args 0 [expr $x -1]]]]
        set mapcubes [lsort [glob {*}[lrange $args [expr $x + 1] end]]]
    }
    if {[llength $mapcubes] == 0} {
        foreach i $basecubes {
            mol new $i type cube
            mol addrep top
            mol modstyle 1 top Isosurface [Vautoiso $i ] 0 0 0 1 1
            mol addrep top
            mol modstyle 2 top Isosurface [Vautoiso $i m] 0 0 0 1 1
			regsub {\.cub$} $i ".pbc" pbcfile
			if {[file exists $pbcfile]} {
				source $pbcfile
				pbc box -color gray
			}
        }
        vstyle my_orb.stl

    } elseif {[llength $mapcubes] == [llength $basecubes]} {
        foreach i $basecubes j $mapcubes {
            mol new $i type cube
            mol addfile $j type cube
            mol addrep top
            mol modstyle 1 top Isosurface [Vautoiso $i] 0 0 0 1 1
            mol modcolor 1 top Volume 1
			regsub {\.cub$} $i ".pbc" pbcfile
			if {[file exists $pbcfile]} {
				source $pbcfile
				pbc box -color gray
			}
        }
		Vautomap $j
        vstyle sob-esp1.mstl
    } else {
        puts "Error! Number of base cubes do not equal number of map cubes"
    }
    vgroup
}

proc ::vcube::vmol {args} {
    # args are list of cube files
    set i 0 
    set first 0
    set last -1
    set step 1
    foreach j $args {
        incr i 
        if {[string match "first" $j]} {
            set first [lindex $args $i]
        }
        if {[string match "last" $j]} {
            set last [lindex $args $i]
        }
        if {[string match "step" $j]} {
            set step [lindex $args $i]
        }
    }
    variable surface_type
    set surface_type norm
    set files [glob {*}$args]
    foreach i $files {
        mol new $i first $first last $last step $step waitfor 1 
    }
    vstyle sob-art.stl
    vgroup
}

proc ::vcube::vrename {str1 str2 args} {
    #rename molecule name by subsitude str1 with str2 for molids in args
    set molids $args
    if {$molids eq ""} {
        set molids all
    } 
    set idlist [parseid {*}$molids]
    foreach i $idlist {
        set cname [molinfo $i get name] 
        regsub -expanded $str1 $cname $str2 newname
        puts "${cname} -> ${newname}"
        mol rename $i $newname
    }
}

# grouplist is a 2D list, the elements are group of molid, not index
proc ::vcube::vgroup {{sep ""} args} {
    variable separator
    variable groupbyidx
    variable grouplist ""
    set filelist ""
    set headerlist ""
    if {[llength $sep] > 1} {
        set separator [lindex $sep 0]
        set groupbyidx [lreplace $sep 0 0]
    } elseif {[llength $sep] == 1} {
        set separator $sep
        set groupbyidx {end-1}
    }
    if {$separator == "by"} {
        puts "group by user defined group"
        set idlist [molinfo list]
        foreach i $idlist {
            set found 0
            foreach g $args {
                set glist [split $g ","]
                if {[lsearch $glist $i] >=0} {
                    lappend grouplist $glist
                    set found 1
                    break
                }
            }
            if {$found == 0} {
                lappend grouplist [list $i]
            }
        }
        puts $grouplist
    } else {
        puts "separator is $separator, identify group by idx $groupbyidx"
        set idlist [molinfo list]
        foreach i $idlist {
            lappend filelist [molinfo $i get name]
        }
        foreach i $filelist {
            if {[string match "-*" $groupbyidx]} { 
                set gb [string trim $groupbyidx "-"] 
                set e [lrange [split $i $separator] 0 $gb]
                set s [lreplace [split $i $separator] 0 $gb]
            } else {
                set s [lrange [split $i $separator] 0 $groupbyidx]
                set e [lreplace [split $i $separator] 0 $groupbyidx]
            }
            set file_header [join $s $separator]
            set file_tailer [join $e $separator]
            lappend headerlist $file_header
            dict lappend groupdict $file_header  $file_tailer
        }
        foreach i $headerlist {
            set group [lsearch -all $headerlist $i]
            set idgroup ""
            foreach g $group {
                lappend idgroup [lindex $idlist $g]
            }
            lappend grouplist $idgroup
            dict lappend groupdict $i $idgroup
        }
        dict for {headname tailname} $groupdict {
            set tmp ""
            foreach e $tailname {dict set tmp $e 1}
            set unique_tail [dict keys $tmp]
            puts [format "%-20s%s" $headname $unique_tail]
        }
    }
}

# call vc to navigate through mol ecules
# with N for next and P for previous
# lower case n and p means free all the molecules of same group 
# which is defined by file name with part after last _ discarde
proc ::vcube::vc {args} {
    # display and free the target molecule 
    mol fix all
    set molids $args
    if {$molids eq ""} {
        set molids all
    }
    set idlist [parseid {*}$molids]
    foreach id $idlist {
        mol free $id
        mol top $id
    }
    Vshow_mol
}

proc ::vcube::vapply {{script_file ""} args} {
    # if no args, this function check all the available script file in script_dir
    # and in current folder that end with .vmd or .tcl
    # else the first argument is style name and the left args are molids
    # If no molid is specified the style will apply to all mol
    global vcube_script_dir
    global style_dir
	set full_name ""
    set i 0
    set id ""
    set vapply_args ""
    foreach j $args {
        incr i 
        if {[string match "-h" $j]} {vhelp vapply;return}
        if {[string match "-id" $j]} {set id [lindex $args $i]}
        if {[string match "-arg" $j]} {set vapply_args [lindex $args $i]}
    }
    if {$vcube_script_dir eq ""} {
        set script_dir $style_dir
    }
    if {$script_file eq ""} {
        # if not specified list all script file name
        puts "scripts found:"
        set current_script [glob -nocomplain *.vmd *.tcl]
        set avail_script [glob -nocomplain [file join ${vcube_script_dir} *.vmd] [file join ${vcube_script_dir} *.tcl]]
        set avail_script [list {*}$current_script {*}$avail_script]
        foreach s $avail_script {
            puts $s
        }
    } else {
        # if specified, check if file exist 
        if {[file exists [file join ${vcube_script_dir} $script_file]] == 1} {
            set full_name [file join ${vcube_script_dir} $script_file]
        } elseif {[file exists [file join ${vcube_script_dir} ${script_file}.vmd]] == 1} {
            set full_name [file join ${vcube_script_dir} ${script_file}.vmd]
        } elseif {[file exists [file join ${vcube_script_dir} ${script_file}.tcl]] == 1} {
            set full_name [file join ${vcube_script_dir} ${script_file}.tcl]
        } elseif {[file exists $script_file] == 1} {
            set full_name $script_file
        } else {
            puts "$script_file not found in ${vcube_script_dir} or current folder"
        }
    }
    if {$full_name != ""} {
        set molids $id
        if {$id eq ""} {
            set molids all
        }
        set idlist [parseid {*}$molids]
        puts "apply $full_name to $idlist"
        foreach i $idlist {
            mol top $i
            source $full_name
        }
    }
}

#######################################################################################################################
# user available change style function
#######################################################################################################################

proc ::vcube::vstyle {{style_name ""} args} {
    # if no args, this function list all the available stylefiles
    # else the first argument is style name and the left args are molids
    # If no molid is specified the style will apply to all mol
    global style_dir
    variable current_style
    variable surface_type
	variable tachyon_user
	variable tachyon_options
    set full_name ""
    if {$surface_type == "map"} {
        set ext .mstl
    } elseif {$surface_type == "norm"} {
        set ext .stl
    }
    # check if style_name is specified
    if {$style_name eq ""} {
        # if not specified list all style name and comment
        set avail_style [glob [file join ${style_dir} *$ext]]
        foreach i $avail_style {
            set basename [file rootname [file tail $i]]
            set fp [open $i]
            set lines [split [read $fp] "\n"]
            set comment [string trim [lindex $lines 0] " #"]
            puts [format "%-20s:%s" $basename $comment]
        }
    } else {
        # if specified, check if file exist 
        if {[file exists [file join ${style_dir} $style_name]] == 1} {
            set full_name $style_name
        } elseif {[file exists [file join ${style_dir} $style_name$ext]] == 1} {
            set full_name $style_name$ext
        } else {
            puts "$style_name not found in ${style_dir}"
        }
    }
    if {$full_name != ""} {
        set current_style $full_name
        source [file join ${style_dir} $current_style]
        set molids $args
        if {$molids eq ""} {
            set molids all
        } 
        set idlist [parseid {*}$molids]
        puts "${idlist} set style to $current_style"
        foreach i $idlist {
            mol top $i
            Vapply_style vcube$i
			if {$tachyon_user != ""} {
				sets tachyon_options $tachyon_user
			}
		}
    }
}

proc ::vcube::vreset {args} {
    # reset view of target molids
    variable show_always
    variable show_switch
    set show_always ""
    set show_switch 0
    if {$args eq ""} {set args [molinfo list]}
    foreach i $args {
        mol free $i
        mol on $i
    }
    display resetview
}

proc ::vcube::viso {args} {
    # set iso for one or more molecules 
    # if no input, then print list of current isovalues
    variable surface_type 
    set reverse 0
    set cube_type ""
    set molids all
    set type2iso [dict create \
                  orb {0.025 -0.025} \
                  esd {0.001 -0.001} \
                  den {0.001 -0.001} \
                  esp {0.001 -0.001} \
                  elf {0.01 -0.01}   \
                  lol {0.01 -0.01}   \
                  hole {0.001 -0.001}\
                  ele {-0.001 0.001} \
                  igmh {0.005 0.005} \
                  igm {0.01 0.01}    \
                  rdg {0.5 0.5}      \
                  iri {1.0 1.0}      \
                  ]
    lassign [lrange $args 0 1] isoplus isominus
    foreach j $args {
        incr i 
        if {[string match "-h" $j]} {vhelp viso;return}
        if {[string match "-r" $j]} {set reverse 1}
        if {[string match "-id" $j]} {set molids [lindex $args $i]}
        if {[string match "-t" $j]} {set cube_type [lindex $args $i]}
    }
    set idlist [parseid {*}$molids]
    if {[dict exists $type2iso $cube_type]} {
        lassign [dict get $type2iso $cube_type] isoplus isominus
    } elseif {$cube_type != ""} {
        puts {available cube type and their iso values are:}
        puts {orb    0.025   -0.025  # molecule orbital}
        puts {esd    0.001   -0.001  # electron spin density}
        puts {den    0.001   -0.001  # electron density}
        puts {elf    0.01    -0.01   # electron localization function}
        puts {lol    0.01    -0.01   # localized orbital locator}
        puts {hole   0.001   -0.001  # hole of excited state}
        puts {ele    -0.001  0.001   # electron of excited state}
        puts {igmh   0.005   0.005   # independent gradient model based on Hirshfeld}
        puts {igm    0.01    0.01    # independent gradient model}
        puts {rdg    0.5     0.5     # reduced density gradient}
        puts {iri    1.0     1.0     # interaction region indicator}
    } 
    if {$args eq ""} {
        foreach i [molinfo list] {
            set isop ""
            set isom ""
            set isop [lindex [molinfo $i get {{rep 1}}] 0 1]
            if {$surface_type != "map"} {
                set isom [lindex [molinfo $i get {{rep 2}}] 0 1]
            }
            if {[molinfo top] eq $i} {
                puts "isovalue of $i is $isop $isom TOP"
            } else {
                puts "isovalue of $i is $isop $isom"
            }
        }
    } 
    if {[string is double -strict $isoplus] && [string is double -strict $isominus]} {
        foreach i $idlist {
            mol modstyle 1 $i Isosurface $isoplus 0 0 0 1 1
            mol modstyle 2 $i Isosurface $isominus 0 0 0 1 1
        }
    }
    if {$reverse == 1} {
		foreach i $idlist {
            set isop ""
            set isom ""
            set isop [lindex [molinfo $i get {{rep 1}}] 0 1]
			set isop [expr $isop * -1]
            if {$surface_type != "map"} {
                set isom [lindex [molinfo $i get {{rep 2}}] 0 1]
				set isom [expr $isom * -1]
            }
	        mol modstyle 1 $i Isosurface $isop 0 0 0 1 1
            mol modstyle 2 $i Isosurface $isom 0 0 0 1 1	
		}
	} 
}

proc ::vcube::valpha {{alpha_value ""} args} {
    set molid [molinfo top]
    if {$alpha_value eq ""} {
        set calpha [lindex [material settings vcube${molid}a] 5]
        puts "current alpha value is $calpha"
    } else {
        set alpha_value [string trimright [format %.4f [expr $alpha_value]] 0]
        set molids $args
        if {$molids eq ""} {
            set molids all
        }
        set idlist [parseid {*}$molids]
        foreach i $idlist {
            material change opacity vcube${i}a $alpha_value
            if {[lsearch [material list] vcube${i}b] > 0} {
                material change opacity vcube${i}b $alpha_value
            }
            puts "alpha is $alpha_value for $i"
        }
    }
}

proc ::vcube::vbond {args} {
    set id top
    set reset 0
    set upper_th 2
    set lower_th 0
    set dset1 ""
    set aset1 ""
    set dset2 ""
    set aset2 ""
    set trace_mode ""
    if {[llength $args] == 0} {
        vhelp vbond
        return
    }
    # parse args
    foreach j $args {
        incr i 
        if {[string match "-a" $j]} {
            set aset1 [lindex $args $i]
            set aset2 [lrange $args [expr $i + 1] [expr $i + 1]]
            set upper_th [lrange $args [expr $i + 2] [expr $i + 2]]
        }
        if {[string match "-d" $j]} {
            set dset1 [lindex $args $i]
            set dset2 [lrange $args [expr $i + 1] [expr $i + 1]]
            set lower_th [lrange $args [expr $i + 2] [expr $i + 2]]
        }
        if {[string match "reset" $j]} {set reset 1}
        if {[string match "-id" $j]}  {set id [lindex $args $i]}
        if {[string match "-t" $j]}  {set trace_mode [lindex $args $i]}
        if {[string match "-h" $j]}  {vhelp vbond;return}
    }
    set idlist [parseid {*}$id]
    # list that store atom selection for all mols
    foreach molid $idlist {
        vc $molid
        # if atoms in system do not have element properties then guess element from name
        set elem_list [lsort -unique [[atomselect top all]  get element]]
        if {[string first "X" $elem_list] != -1} {
            puts "X element detected in all elements: $elem_list, try to guess element from atom_name via following command:"
            puts "topo guessatom element name"        
            topo guessatom element name
            set elem_list [lsort -unique [[atomselect top all]  get element]]
            puts "now all elements in system are $elem_list"
        }
        set aidx1 [parsesel $aset1]
        set aidx2 [parsesel $aset2]
        set didx1 [parsesel $dset1]
        set didx2 [parsesel $dset2]
        if { $reset == 1 } {
            mol bondsrecalc all
            topo retypebonds
        }
        if {[llength $aidx1] >= 1 && [llength $aidx2] >= 1 } {
            set count 0
            set bond_count 0
            set total [llength $aidx1]
            foreach i1 $aidx1 {
                set i1n [[atomselect top "index $aidx2 and exwithin $upper_th of index $i1"] list]
                set count [expr $count + 1]
                set bond_count [expr $bond_count + [llength $i1n]]
                flush stdout
                puts -nonewline "\rmolid: $molid   Progress: $count/$total"
                foreach i2 $i1n {
                    topo addbond $i1 $i2
                }
            }
            puts ""
            puts "$bond_count bonds added"
        }
        if {[llength $didx1] >= 1 && [llength $didx2] >= 1 } {
            set allbond [topo getbondlist]
            set total [llength $allbond]
            if {[expr [llength $didx1] * [llength $didx2]] > [expr $total/2]} {
                set count 0
                set del_count 0
                foreach bond $allbond {
                    set count [expr $count + 1]
                    set a1 [lindex $bond 0]
                    set a2 [lindex $bond 1]
                    if {($a1 in $didx1 && $a2 in $didx2) || ($a2 in $didx1 && $a1 in $didx2 )} {
                        if {[measure bond "$a1 $a2"] > $lower_th} {
                            set del_count [expr $del_count + 1]
                            topo delbond $a1 $a2
                        }
                    }
                    puts -nonewline "\rmolid: $molid   Progress: $count/$total"
                }
            } else {
                set count 0
                set del_count 0
                set total [llength $didx1]
                foreach i1 $didx1 {
                    set count [expr $count + 1]
                    foreach i2 $didx2 {
                        if {[measure bond "$i1 $i2"] > $lower_th} {
                            set del_count [expr $del_count + 1]
                            topo delbond $i1 $i2
                        }
                        flush stdout
                        puts -nonewline "\rmolid: $molid   Progress: $count/$total"
                    }
                }
            }
            puts ""
            puts "$del_count bonds have been removed"
        }
    }
    if {$trace_mode == "on"} {
        set idx [lsearch $args "-t"]
        set args [lreplace $args $idx [expr $idx + 1]]
        set idx_id [lsearch $args "-id"]
        if {$idx_id > -1} {
            set args [lreplace $args $idx_id [expr $idx_id + 1]]
        }
        global vmd_frame
        foreach com [trace info variable vmd_frame([molinfo top])] {
            trace remove variable vmd_frame([molinfo top]) {*}$com
        }
        trace add variable vmd_frame([molinfo top]) write "vbond $args"
    }
    if {$trace_mode == "off"} {
        global vmd_frame
        foreach com [trace info variable vmd_frame([molinfo top])] {
            trace remove variable vmd_frame([molinfo top]) {*}$com
        }
    }
}

proc ::vcube::vcscale {{cs ""}} {
    variable color_scale
    if {$cs eq ""} {
        puts "mapped color scalar is $color_scale"
		puts "available color scales are:"
		puts "RWB BWR RGryB BGryR RGB BGR RWG GWR GWB BWG BlkW WBlK"
    } else {
        # set mapped scale
		set color_scale $cs
		color scale method $color_scale
        puts "color scale is $color_scale"
    }
}

proc ::vcube::vmscale {{v1 ""} {v2 ""} args} {
    variable map_scale_value
    if {$v1 eq ""} {
        puts "map scale value is $map_scale_value"
    } else {
        # set mapped scale
        set molids $args
        if {$molids eq ""} {
            set molids all
        }
        set idlist [parseid {*}$molids]
        foreach i $idlist {
            mol scaleminmax $i 1 $v1 $v2
        }
        set map_scale_value "$v1 $v2"
        puts "Min Max mapped value is $v1 $v2"
    }
}
#######################################################################################################################
# user available draw and annotation function
#######################################################################################################################

proc ::vcube::varrow {args} {
    # draw an arrow
    if {$args eq ""} {
        vhelp varrow 
        return
    }
    set xyz [lrange $args 0 2]
    set start {0 0 0}
    set origin {0 0 0}
    set position 0
    set radius 0.1
    set scale 1
    set id top
    set idlist top
    set color blue
    set material "Diffuse"
    set resolution 30 
    set conesize 0.2
    set coneratio 2
    set delete 0
    set double 0
    set i 0 
    foreach j $args {
        incr i 
        if {[string match "-h" $j]} {vhelp varrow;return}
        if {[string match "-b" $j]} {set start [lrange $args $i [expr $i + 2]]}
        if {[string match "-p" $j]} {set position [lindex $args $i]}
        if {[string match "-o" $j]} {set origin [lrange $args $i [expr $i + 2]]}
        if {[string match "del*" $j]} {set delete 1}
        if {[string match "-double" $j]} {set double 1}
        if {[string match "-r" $j]} {set radius [lindex $args $i];set conesize [expr $radius * 3]}
        if {[string match "-s" $j]} {set scale [lindex $args $i]}
        if {[string match "-id" $j]} {set id [lindex $args $i]}
        if {[string match "-c" $j]} {set color [lindex $args $i]}
        if {[string match "-mat" $j]} {set material [lindex $args $i]}
        if {[string match "-res" $j]} {set resolution [lindex $args $i]}
        if {[string match "-cs" $j]} {set conesize [lindex $args $i]}
        if {[string match "-cr" $j]} {set coneratio [lindex $args $i]}
    }
    proc vec_len {v1} {
        set d 0
        foreach c1 $v1 {set d [expr {$d + $c1*$c1}]}
        expr {sqrt($d)}
    }
    set idlist [parseid {*}$id]
    if {$delete eq 1} {
        foreach molid $idlist {
            graphics $molid delete all
        }
        return
    }
    foreach i $xyz {
        if {[string is double $i] == 0} {
            puts "Wrong input format"
            vhelp varrow
            return
        }
    }
    set begin {}
    foreach s $start o $origin {lappend begin [expr {$s + $o}]}
    set end {}
    foreach c $xyz o $origin {lappend end [expr {$c * $scale + $o}]}
    set nb {}
    set ne {}
    foreach b $begin e $end o $origin {
        lappend nb [expr {$b - $position * ($e - $o)}]
        lappend ne [expr {$e - $position * ($e - $o)}]
    }
    set begin $nb
    set end $ne
    set conelen [expr $conesize * $coneratio]
    set b2e {}
    foreach e $end b $begin {lappend b2e [expr {$e - $b}]}
    set v12 [vec_len $b2e]
    set mscale [expr ($v12 - $conelen)/$v12]
    set ascale [expr $conelen/$v12]
    set mid {}
    foreach e $end b $begin {lappend mid [expr $b+($e - $b)*$mscale]}
    set mid2 {}
    foreach e $end b $begin {lappend mid2 [expr $b+($e - $b)*$ascale]}
    foreach molid $idlist {
        graphics $molid color $color
        if {$material eq ""} {
            graphics $molid materials off
        } else {
            graphics $molid materials on
            graphics $molid material $material
        }
        puts "graphics $id cylinder $begin $mid radius $radius resolution $resolution filled no"
        if {$double == 0} {
            graphics $id cylinder $begin $mid radius $radius resolution $resolution filled no
            graphics $id cone $mid $end radius $conesize resolution $resolution
        } else {
            graphics $id cylinder $mid2 $mid radius $radius resolution $resolution filled no
            graphics $id cone $mid $end radius $conesize resolution $resolution
            graphics $id cone $mid2 $begin radius $conesize resolution $resolution
        }
    }
}

proc ::vcube::vlabel {args} {  
    set delete 0
    set type {%1i}
    set sel all
    set file ""
    variable label_color
    variable label_size
    variable label_thick 
    set file ""
    set id top
    foreach j $args {
        incr i 
        if {[string match "-f" $j]}  {set file [lindex $args $i]}
        if {[string match "-type" $j]} {set type [lindex $args $i]}
        if {[string match "-sel*" $j]}  {set sel [lindex $args $i]}
        if {[string match "-c" $j]} {set label_color [lindex $args $i]}
        if {[string match "-s" $j]}  {set label_size [lindex $args $i]}
        if {[string match "-t" $j]}  {set label_thick [lindex $args $i]}
        if {[string match "-id" $j]}  {set id [lindex $args $i]}
        if {[string match "del*" $j]}  {set delete 1}
    }
    if {$delete eq 1} {
        label delete Atoms all
        return
    }
    set idlist [parseid {*}$id]
    # list that store atom selection for all mols
    foreach molid $idlist {
        vc $molid
        # first delete all label of current mol
        set current_albid [lsearch -index 0 -all [label list Atoms] "${molid} *"]
        set current_albid [lsort -integer -decreasing $current_albid]
        foreach alb_id $current_albid {
            label delete Atoms $alb_id
        }
        # max_idx is the atom label index, which is indexed across molecule
        set max_idx [llength [label list Atoms]]
        set atomlist [[atomselect $molid $sel] list]
        append all_sel_alb [lmap x $atomlist {expr {$x + $max_idx}}] " "
        set allatom [[atomselect $molid all] list]
        set label_format $type
        if {$file != ""} {
            set label_data [split [read [open $file r]] "\n"]
            foreach {atom} $allatom {data} $label_data {
                set atomlabel [format "%d/%d" $molid $atom]
                label add Atoms $atomlabel
                label textformat Atoms $max_idx $data
                incr max_idx
            }
        } else {
            foreach {atom} $allatom {
                set atomlabel [format "%d/%d" $molid $atom]
                label add Atoms $atomlabel
                label textformat Atoms $max_idx $label_format
                incr max_idx
            }
        }
        set current_albid [lsearch -index 0 -all [label list Atoms] "${molid} *"]
        foreach alb_id $current_albid {
            label hide Atoms $alb_id
        }
    }
    foreach {atom} $all_sel_alb {
        label show Atoms $atom
    }
    color Labels Atoms $label_color
    label textsize $label_size
    label textthickness $label_thick
}

proc ::vcube::vmeasure {args} {  
    set delete 0
    set bonds ""
    set angles ""
    set dihedrals ""
    set bset1 ""
    set bset2 ""
    set upper_th 3
    variable measure_color
    variable label_size 
    variable label_thick
    set id top
    if {$args == ""} {
        vhelp vmeasure
    }
    foreach j $args {
        incr i 
        if {[string match "color" $j]} {dict set measure_color {*}[lrange $args $i [expr $i+1]]}
        if {[string toupper $j] == "B"} {lappend bonds [lrange $args $i [expr $i+1]]}
        if {[string toupper $j] == "MB"} {
            set bset1 [lindex $args $i]
            set bset2 [lrange $args [expr $i + 1] [expr $i + 1]]
            set lower_th [lrange $args [expr $i + 2] [expr $i + 2]]
            set upper_th [lrange $args [expr $i + 3] [expr $i + 3]]
        }
        if {[string toupper $j] == "A"} {lappend angles [lrange $args $i [expr $i+2]]}
        if {[string toupper $j] == "D"} {lappend dihedrals [lrange $args $i [expr $i+3]]}
        if {[string match "size" $j]}  {set label_size [lindex $args $i]}
        if {[string match "thick" $j]}  {set label_thick [lindex $args $i]}
        if {[string match "id" $j]}  {set id [lindex $args $i]}
        if {[string match "del*" $j]}  {set delete 1}
    }
    if {$delete eq 1} {
        label delete Bonds all
        label delete Angles all
        label delete Dihedrals all
        return
    }
    set idlist [parseid {*}$id]
    # list that store atom selection for all mols
    foreach molid $idlist {
        vc $molid
        if {$bset1 != "" && $bset2 != ""}  {
            # if atoms in system do not have element properties then guess element from name
            set elem_list [lsort -unique [[atomselect top all]  get element]]
            if {[string first "X" $elem_list] != -1} {
                puts "X element detected in all elements: $elem_list, try to guess element from atom_name via following command:"
                puts "topo guessatom element name"        
                topo guessatom element name
                set elem_list [lsort -unique [[atomselect top all]  get element]]
                puts "now all elements in system are $elem_list"
            }
            set bidx1 [parsesel $bset1]
            set bidx2 [parsesel $bset2]
            if {[llength $bidx1] >= 1 && [llength $bidx2] >= 1 } {
                set mbonds ""
                set count 0
                set bond_count 0
                set total [llength $bidx1]
                puts $lower_th
                puts $upper_th
                foreach i1 $bidx1 {
                    set i1n [[atomselect top "index $bidx2 and (exwithin $upper_th of index $i1) and not (exwithin $lower_th of index $i1)"] list]
                    set count [expr $count + 1]
                    set bond_count [expr $bond_count + [llength $i1n]]
                    flush stdout
                    puts -nonewline "\rmolid: $molid   Progress: $count/$total"
                    foreach i2 $i1n {
                        lappend mbonds "[expr $i1 + 1] [expr $i2 + 1]"
                    }
                }
                puts ""
                puts "$bond_count bonds measure found for $bset2 within $upper_th of $bset1"
                if {[llength $mbonds] > 0} {
                    foreach b $mbonds {
                        lassign [lmap serial $b {expr $serial - 1}] a1 a2
                        set bondlabel [format "%d/%d %d/%d" $molid $a1 $molid $a2]
                        label add Bonds {*}$bondlabel
                    }
                }
            }
        }
        foreach b $bonds {
            lassign [lmap serial $b {expr $serial - 1}] a1 a2
            set bondlabel [format "%d/%d %d/%d" $molid $a1 $molid $a2]
            label add Bonds {*}$bondlabel
        }
        foreach a $angles {
            lassign [lmap serial $a {expr $serial - 1}] a1 a2 a3
            set anglelabel [format "%d/%d %d/%d %d/%d" $molid $a1 $molid $a2 $molid $a3]
            label add Angles {*}$anglelabel
        }
        foreach d $dihedrals {
            lassign [lmap serial $d {expr $serial - 1}] a1 a2 a3 a4
            set dihedrallabel [format "%d/%d %d/%d %d/%d %d/%d" $molid $a1 $molid $a2 $molid $a3 $molid $a4]
            label add Dihedrals {*}$dihedrallabel
        }
    }
    foreach {k v} $measure_color {
        if {$k == "bond"} {color Labels Bonds $v}
        if {$k == "angle"} {color Labels Angles $v}
        if {$k == "dihedral"} {color Labels Dihedrals $v}
    }
    label textsize $label_size
    label textthickness $label_thick
}



#######################################################################################################################
# shortcut key-bind function
#######################################################################################################################
proc ::vcube::Vnav_style {direction} {
    # direction argument accept n or p for next or previous
    variable surface_type
    variable current_style
    global style_dir
    if {![info exists surface_type]} {
        set mol_info [list {*}[mol list top]]
        set repidx [expr [lsearch $mol_info Atom] + 2]
        set repnum [lindex $mol_info $repidx]
        puts "$repnum"
        if {$repnum == 1} {set surface_type norm}
        if {$repnum == 2} {set surface_type map}
        if {$repnum == 3} {set surface_type norm}
        puts "set surface_type to $surface_type base on number of reps"
    }
    if {$surface_type == "map"} {
        set avail_style [glob [file join ${style_dir} *.mstl]]
    } elseif {$surface_type == "norm"} {
        set avail_style [glob [file join ${style_dir} *.stl]]
    }
    set all_style ""
    foreach as $avail_style {
        lappend all_style [file tail $as]
    }
    set cidx [lsearch $all_style $current_style] 
    set nidx [expr {$cidx + 1}]
    set pidx [expr {$cidx - 1}]
    if {$nidx >= [llength $all_style]} {set nidx 0}
    if {$pidx < 0} {set pidx [expr [llength $all_style] - 1]}
    puts "available styles: $all_style"
    set nstyle [lindex $all_style $nidx]
    set pstyle [lindex $all_style $pidx]
    if {$direction eq "n"} {
        vstyle $nstyle
    } elseif {$direction eq "p"} {
        vstyle $pstyle
    }
}

proc ::vcube::Vnav_mscale {direction} {
    variable map_scale_value
    set lsv [lindex $map_scale_value 0]
	set usv [lindex $map_scale_value 1]
	set ldsv [expr abs([Vcalc_delta $lsv])]
	set udsv [expr abs([Vcalc_delta $usv])]
	
    if {$direction eq "l"} {
		set lsv [expr $lsv - $ldsv ]
    } elseif {$direction eq "u"} {
		set lsv [expr $lsv + $ldsv ]
    } elseif {$direction eq "r"} {
		set usv [expr $usv + $udsv ]
    } elseif {$direction eq "d"} {
		set usv [expr $usv - $udsv ]
    }
	set usv [string trimright [format %.8f $usv] 0]
	set lsv [string trimright [format %.8f $lsv] 0]
	vmscale $lsv $usv
}

proc ::vcube::Vnav_cscale {direction} {
    variable color_scale
    set cslist "RWB BWR RGryB BGryR RGB BGR RWG GWR GWB BWG BlkW WBlK"
    set cidx [lsearch $cslist $color_scale]
    set nidx [expr {$cidx + 1}]
    set pidx [expr {$cidx - 1}]
    if {$nidx >= [llength $cslist]} {set nidx 0}
    if {$pidx < 0} {set pidx [expr [llength $cslist] - 1]}
    set nc [lindex $cslist $nidx]
    set pc [lindex $cslist $pidx]
    if {$direction eq "n"} {
		vcscale $nc
    } elseif {$direction eq "p"} {
		vcscale $pc
    }
}

proc ::vcube::Vnav_mol {direction} {
    variable grouplist
    set idlist [molinfo list]
    set id [molinfo top]
    set cidx [lsearch $idlist $id]
    set nidx [expr {$cidx + 1}]
    set pidx [expr {$cidx - 1}]
    if {$nidx >= [llength $idlist]} {set nidx 0}
    if {$pidx < 0} {set pidx [expr [llength $idlist] - 1]}
    set nid [lindex $idlist $nidx]
    set pid [lindex $idlist $pidx]
    if {$direction eq "n"} {
        vc $nid 
        Vfree_mol [lindex $grouplist $nidx]
    } elseif {$direction eq "p"} {
        vc $pid
        Vfree_mol [lindex $grouplist $pidx]
    }
    if {$direction eq "N"} {
        vc $nid 
    } elseif {$direction eq "P"} {
        vc $pid
    }
}


#increase or decrease iso value
proc ::vcube::Vnav_iso {direction} {
    variable global_adj
    if {$global_adj == 0} {
        Vadj_iso top $direction
    } elseif {$global_adj == 1} {
        foreach i [molinfo list] {
            Vadj_iso $i $direction
        }
    }
}
proc ::vcube::Vadj_iso {molid direction} {
    variable surface_type
    set isop [lindex [molinfo $molid get {{rep 1}}] 0 1]
    set isodp [Vcalc_delta $isop]
    set isopp [string trimright [format %.10f [expr $isop + $isodp]] 0]
    set isopm [string trimright [format %.10f [expr $isop - $isodp]] 0]
    if {$surface_type != "map"} {
        set isom [lindex [molinfo $molid get {{rep 2}}] 0 1]
        set isodm [Vcalc_delta $isom]
        set isomp [string trimright [format %.10f [expr $isom + $isodm]] 0]
        set isomm [string trimright [format %.10f [expr $isom - $isodm]] 0]
    } else {
        set isomm 0
        set isomp 0
    }
    if {$direction eq "n"} {
        viso $isopp $isomp $molid
        puts "isovalue is $isopp $isomp for $molid"
    } elseif {$direction eq "p"} {
        viso $isopm $isomm $molid
        puts "isovalue is $isopm $isomm for $molid"
    }
}

# used to switch variable global_adj
# which is to specify whether the adjustment is local or global
proc ::vcube::Vglobal_switch {} {
    variable global_adj
    if {$global_adj == 0} {
        set global_adj 1
        puts "adjust global"
    } elseif {$global_adj == 1} {
        set global_adj 0
        puts "adjust local"
    }
}

proc ::vcube::Vshow_switch {} {
    variable show_switch
    if {$show_switch == 0} {
        set show_switch 1
        puts "show group"
        Vshow_mol
    } elseif {$show_switch == 1} {
        set show_switch 2
        puts "show all"
        Vshow_mol
    } elseif {$show_switch == 2} {
        set show_switch 0
        puts "show top"
        Vshow_mol
    }
}

#show specific molecule based on show_switch
proc ::vcube::Vshow_mol {} {
    variable show_switch
    variable show_always
    variable grouplist
    mol off all
    if {$show_switch == 0} {
        mol on top
    } elseif {$show_switch == 2} {
        mol on all
    } elseif {$show_switch == 1} {
        set idlist [molinfo list]
        set id [molinfo top]
        set cidx [lsearch $idlist $id]
        set cgroup [lindex $grouplist $cidx]
        foreach i $cgroup {
            mol on $i
        }
    }
    foreach i $show_always {
        mol on $i
    }
}

proc ::vcube::vshowalways {args} {
    variable show_always
    if {$args eq ""} {
        set show_always ""
    } else {
        set show_always $args
    }
    puts "always show $args"
    Vshow_mol
}

proc ::vcube::Vnav_alpha {direction} {
    variable global_adj
    if {$global_adj == 0} {
        set mol_id [molinfo top]
        Vadj_alpha $mol_id $direction
    } elseif {$global_adj == 1} {
        foreach i [molinfo list] {
            Vadj_alpha $i $direction
        }
    }
}

proc ::vcube::Vadj_alpha {mol_id direction} {
    set calpha [lindex [material settings vcube${mol_id}a] 5]
    if {$direction eq "n"} {
        set calpha [expr $calpha + 0.05]
        if {$calpha > 1} {set calpha 1}
        valpha $calpha $mol_id
    } elseif {$direction eq "p"} {
        set calpha [expr $calpha - 0.05]
        if {$calpha < 0} {set calpha 0}
        valpha $calpha $mol_id
    }    
}

#######################################################################################################################
# user available export and render function
#######################################################################################################################
proc ::vcube::render_ospay {{scale 3} {suffix ""} {ses ""} {renderid ""}} {
    render aasamples TachyonLOSPRayInternal 24
    render aosamples TachyonLOSPRayInternal 24
    lassign [display get size] w h
    set res "[expr $w * $scale] [expr $h * $scale]"
    set wkdir [file join [pwd] "VCUBE"]
    if {[llength $renderid] == 0 } {
        set outfile  [file join $wkdir ${suffix}.ppm]
        display resize {*}$res
        render TachyonLOSPRayInternal $outfile
    } else {
        foreach i $renderid basename [getname {*}$renderid]  {
            vc $i
            if {$no_frame > 1 && [llength $ses] == 3]} {
                lassign $ses start end sep
                if {$end < 0} {set end [$no_frame + $end + 1]}
                for {set i $start} {$i < $end} {incr [$sep+1]} {
                    animate goto $i
                    set index [format %04s $i]
                    set outbase  ${basename}${suffix}_${index}
                    set outfile  [file join $wkdir ${outbase}.ppm]
                    display resize {*}$res
                    render TachyonLOptiXInternal $outfile
                }
            } else {
                set outfile  [file join $wkdir ${basename}${suffix}.ppm]
                display resize {*}$res
                render TachyonLOSPRayInternal $outfile
            }
        }
    }
}

proc ::vcube::render_optix {{scale 3} {suffix ""} {ses ""} {renderid ""}} {
    render aasamples TachyonLOptiXInternal 24
    render aosamples TachyonLOptiXInternal 24
    lassign [display get size] w h
    set res "[expr $w * $scale] [expr $h * $scale]"
    set wkdir [file join [pwd] "VCUBE"]
    if {[llength $renderid] == 0 } {
        set outfile  [file join $wkdir ${suffix}.ppm]
        display resize {*}$res
        render TachyonLOSPRayInternal $outfile
    } else {
        foreach i $renderid basename [getname {*}$renderid]  {
            vc $i
            if {$no_frame > 1 && [llength $ses] == 3]} {
                lassign $ses start end sep
                if {$end < 0} {set end [$no_frame + $end + 1]}
                for {set i $start} {$i < $end} {incr [$sep+1]} {
                    animate goto $i
                    set index [format %04s $i]
                    set outbase  ${basename}${suffix}_${index}
                    set outfile  [file join $wkdir ${outbase}.ppm]
                    display resize {*}$res
                    render TachyonLOptiXInternal $outfile
                }
            } else {
                set outfile  [file join $wkdir ${basename}${suffix}.ppm]
                display resize {*}$res
                render TachyonLOptiXInternal $outfile
            }
        }
    }
}

proc ::vcube::add_toplayer {label_flag tachyon_cmd full_options batchfile shfile {basename ""} {suffix ""} {index ""}} {
    # add render command for the top layer like label or arrow
    variable composite_com
    variable convert_com
    global compose
    if {$label_flag == 1 && $composite_com != ""} {
        if {[string trim $compose] != ""} {
            if {[string first : $compose] != -1} {
                lassign [split $compose :] method arg
                set compose_method "$method -define compose:args=$arg"
            } else {
                set compose_method $compose
            }
        } else {
            set compose_method Multiply
        }
        if {[string trim $index] != ""} {
            set index "_ $index"
        }
        switch_rep 0
        set scriptname ${basename}${suffix}_label${index}.dat
        set outlabel ${basename}${suffix}_label${index}.bmp
        set outlabel_trans ${basename}${suffix}_label${index}.png
        set outfile ${basename}${suffix}${index}.bmp
        render Tachyon [file join "VCUBE" $scriptname]
        puts $batchfile "\"$tachyon_cmd\" \"$scriptname\" $full_options -o \"$outlabel\""
        puts $batchfile "$convert_com \"$outlabel\" -fill none -fuzz 15%% -draw \"alpha 0,0 replace\" \"$outlabel_trans\""
        puts $batchfile "$composite_com \"$outlabel_trans\" \"$outfile\" -compose $compose_method \"$outfile\""
        puts $shfile "\"\$tachyon_cmd\" \"$scriptname\" $full_options \$NC -o \"$outlabel\""
        puts $shfile "$convert_com \"$outlabel\" -fill none -fuzz 10% -draw \"alpha 0,0 replace\" \"$outlabel_trans\""
        puts $shfile "$composite_com \"$outlabel_trans\" \"$outfile\" -compose $compose_method \"$outfile\""
        switch_rep 1
    }
}

proc ::vcube::vtachyopt {{option_name ""}} {
	variable tachyon_user
	variable tachyon_options
	if {$option_name == ""} {
		puts "Current tachyon options is $tachyon_options"
		puts "available tachyon options are (** for default):"
		puts "-trans_raster3d / -trans_vmd / -trans_orig**"
		puts "-shadow_filter_on** / -shadow_filter_off"
		puts "-numthreads 8"
	} else {
		set tachyon_options $option_name
		set tachyon_user $option_name
	}
}

proc ::vcube::render_tachyon {args} {
    # engine function for render with tachyon
    # -s set scale
    # -ses set start end sep for multiframe render, these value must be set if frame render is needed 
    # -id sed molid to render
    # -fps set fps for movie
    # -animate set animate format gif or mp4
    # -silent turn on the silent mode, used in vrenders -preview mode
    variable tachyon_defaults
    variable tachyon_options
    variable composite_com
    variable ffmpeg_com
    variable convert_com
    global tcl_platform
    global compose
    set scale 3
    set suffix ""
    set ses ""
    set renderid ""
    set fps 30
    set animate mp4
    set silent 0
    foreach j $args {
        incr i 
        if {[string match "-s" $j]} {set scale [lindex $args $i]}
        if {[string match "-suf" $j]} {set suffix [lindex $args $i]}
        if {[string match "-ses" $j]} {set ses [lindex $args $i]}
        if {[string match "-id" $j]} {set renderid [lindex $args $i]}
        if {[string match "-fps" $j]} {set fps [lindex $args $i]}
        if {[string match "-ani" $j]} {set animate [lindex $args $i]}
        if {[string match "-silent" $j]} {set silent 1}
    }
    set wkdir [file join [pwd] "VCUBE"]
    lassign [display get size] w h
    set res "[expr $w * $scale] [expr $h * $scale]"
    set tachyon_cmd [lindex [regsub \" [regsub \" [render options Tachyon] \{] \}] 0]
    if {[llength [label list Atoms]] > 0 || [llength [label list Bonds]] > 0 || [llength [label list Angles]] > 0 || [llength [label list Dihedrals]] } {
        set label_flag 1
    } elseif {[string trim $compose] != ""} {set label_flag 1} else {set label_flag 0}
    #generate windows batch render file
    set full_options "$tachyon_defaults -res $res $tachyon_options"
    set NC_win "-numthreads [Vnthread]"
    puts "tachyon options: $full_options"
    set batchfile [open [file join $wkdir renderall.bat] w]
	#generate linux batch render file
	set full_options "$tachyon_defaults -res $res $tachyon_options"
	set shfile [open [file join $wkdir renderall.sh] w]
	fconfigure $shfile -translation lf
	puts $shfile "if \[ -n \"\$1\" \];then NC=\"-numthreads \$1\";fi"
	puts $shfile "tachyon_cmd=\$(which tachyon_LINUXAMD64)"
	puts $shfile "if \[ -z \"\$tachyon_cmd\" \];then"
	puts $shfile "tachyon_cmd=\$(which vmd | sed 's/bin\\/vmd/lib\\/vmd\\/tachyon_LINUXAMD64/')"
	puts $shfile "fi"
    set total_fig 0 
    if {[llength $renderid] == 0 } {
        # for vrenders
        incr total_fig
        # render current scene
        set scriptname ${suffix}.dat
        set outfile  ${suffix}.bmp
        render Tachyon [file join "VCUBE" $scriptname]
        puts $batchfile "\"$tachyon_cmd\" \"$scriptname\" $full_options $NC_win -o \"$outfile\""
        puts $shfile "\"\$tachyon_cmd\" \"$scriptname\" $full_options \$NC -o \"$outfile\""
        add_toplayer $label_flag $tachyon_cmd $full_options $batchfile $shfile ${suffix}
    } 
    if {[llength $renderid] >0 } {
        foreach i $renderid basename [getname {*}$renderid] {
            vc $i
            set scriptname ${basename}${suffix}.dat
            set outfile ${basename}${suffix}.bmp
            set no_frame [molinfo top get numframes]
            if {$no_frame > 1 && [llength $ses] == 3} {
                lassign $ses first last step
                if {$last < 0} {set end [expr $no_frame + $last + 1]}
                if {$first < 0} {set first [expr $no_frame + $last + 1]}
                set total_frame [expr ($end - $first)/$step + 1]
                set total_time [format "%.2f" [expr $total_frame/($fps+0.0)]]
                set fig_list_ffmpeg [open [file join $wkdir figFFmpeg_${basename}${suffix}.txt] w]
                set fig_list_magick [open [file join $wkdir figMagick_${basename}${suffix}.txt] w]
                if {$animate == "mp4" || $animate == "gif"} {
                    puts "$total_frame frames and the movie length is ${total_time}s with fps $fps, continue?(Y/n)"
                } else {
                    puts "-animate format $animate not support"
                    return
                }
                gets stdin continue_flag
                if {[string match -nocase "n*" $continue_flag]} {return}
                for {set i $first} {$i < $end} {incr i $step} {
                    incr total_fig
                    animate goto $i
                    set index [format %05s $i]
                    set outbase  ${basename}${suffix}_${index}
                    set scriptname ${outbase}.dat
                    set outfile ${outbase}.bmp
                    render Tachyon [file join "VCUBE" $scriptname]
                    puts $batchfile "\"$tachyon_cmd\" \"$scriptname\" $full_options $NC_win -o \"$outfile\""
                    puts $shfile "\"\$tachyon_cmd\" \"$scriptname\" $full_options \$NC -o \"$outfile\""
                    puts $fig_list_ffmpeg "file $outfile"
                    puts $fig_list_ffmpeg "duration 0"
                    puts $fig_list_magick "$outfile"
                    add_toplayer  $label_flag $tachyon_cmd $full_options $batchfile $shfile $basename $suffix $index
                }
                close $fig_list_ffmpeg
                close $fig_list_magick
                if {$ffmpeg_com != "" && $animate == "mp4"} {
                    set full_com  "$ffmpeg_com -r $fps -f concat -i figFFmpeg_${basename}${suffix}.txt -c:v libx264 -pix_fmt yuv420p ${basename}${suffix}.mp4"
                    puts $batchfile $full_com
                    puts $shfile $full_com
                } elseif {$ffmpeg_com != "" && $animate == "gif"} {
                    set full_com  "$ffmpeg_com -r $fps -f concat -i figFFmpeg_${basename}${suffix}.txt ${basename}${suffix}.gif"
                    puts $batchfile $full_com
                    puts $shfile $full_com
                } elseif {$convert_com != "" && $animate == "gif"} {
                    set delay [format %.2f [expr {100.0/$fps}]]
                    set full_com  "$convert_com -delay $delay @figMagick_${basename}${suffix}.txt ${basename}${suffix}.gif"
                    puts $batchfile $full_com
                    puts $shfile $full_com
                } else {
                    set full_com  "ffmpeg -r $fps -f concat -i figFFmpeg_${basename}${suffix}.txt -c:v libx264 -pix_fmt yuv420p ${basename}${suffix}.mp4"
                } 
                if {$animate == "mp4"} {
                    # give user command hint is ffmpeg command and imagemagick command not found
                    puts "command to generate mp4:"
                    puts "ffmpeg -r $fps -f concat -i figFFmpeg_${basename}${suffix}.txt -c:v libx264 -pix_fmt yuv420p ${basename}${suffix}.mp4" 
                } elseif {$animate == "gif"} {
                    puts "command to generate gif:"
                    puts "ffmpeg -r $fps -f concat -i figFFmpeg_${basename}${suffix}.txt ${basename}${suffix}.gif" 
                    set delay [format %.2f [expr 100.0/$fps]]
                    pruts "or"
                    puts "convert -delay $delay @figMagick_${basename}${suffix}.txt ${basename}${suffix}.gif"
                }
            } else {
                # for vrender
                incr total_fig
                render Tachyon [file join "VCUBE" $scriptname]
                puts $shfile "\"\$tachyon_cmd\" \"$scriptname\" $full_options \$NC -o \"$outfile\""
                puts $batchfile "\"$tachyon_cmd\" \"$scriptname\" $full_options $NC_win -o \"$outfile\""
                add_toplayer $label_flag $tachyon_cmd $full_options $batchfile $shfile $basename $suffix ""
            }
        }
    }
	close $shfile
    close $batchfile
    set runcmd_win [file join $wkdir renderall.bat]
    set runcmd_linux [file join $wkdir renderall.sh]
    if {$silent == 1} {
        if {$tcl_platform(platform) eq "windows"} {
            cd VCUBE
            exec [auto_execok cmd] /c [file nativename $runcmd_win] <@stdin >@stdout 2>@stderr
            cd ..
        }
        if {$tcl_platform(platform) eq "unix"} {
            cd VCUBE
            exec [auto_execok bash] [file native name $runcmd_linux] <$stdin >@stdout 2>@stderr
            cd ..
        }
        return
    } 
    puts "nproc:[Vnthread], No. figs:${total_fig}, resolution:$res. Render Now?(Y/n)"
	gets stdin render_flag
	if {[string match -nocase "n*" $render_flag]} {
        if {$tcl_platform(platform) eq "windows"} {
            puts "you need to run $runcmd_win manually to render images"
            exec {*}[auto_execok start] "" $wkdir
        }
        if {$tcl_platform(platform) eq "unix"} {
            puts "you need to run $runcmd_linux manually to render images"
        }
	} else {
        if {$tcl_platform(platform) eq "windows"} {
            puts "run $runcmd_win now..."
			cd VCUBE
            exec {*}[auto_execok start] "" $runcmd_win
			cd ..
        }
        if {$tcl_platform(platform) eq "unix"} {
            puts "run $runcmd_linux now..."
			cd VCUBE
            exec {*}[auto_execok bash] $runcmd_linux >@stdout
			cd ..
        }
	}
}

proc ::vcube::vrender {args} {
    set suffix ""
    set scale 3
    set id all
    set i 0
    set fps 0
    set animate ""
    set render_obj 0
    foreach j $args {
        incr i 
        if {[string match "-h" $j]} {vhelp vrender;return}
        if {[string match "-s" $j]} {set scale [lindex $args $i ]}
        if {[string match "-suf" $j]} {set suffix [lindex $args $i]}
        if {[string match "-id" $j]} {set id [lindex $args $i]}
        if {[string match "-fps" $j]} {set fps [lindex $args $i]}
        if {[string match "-obj*" $j]} {set render_obj 1}
        if {[string match "-ani*" $j]} {set animate [lindex $args $i $i]}
    }
    set idlist [parseid {*}$id]
    global optix
    global ospray
    variable show_switch
    variable grouplist
    set suffix [string trim $suffix]
    file mkdir VCUBE
    if {$show_switch == 0} {
        set renderid $idlist
    } elseif {$show_switch == 1} {
        set group1st ""
        foreach g $grouplist {
            foreach i $idlist {
                if {[lsearch $g $i] > 0} {
                    lappend group1st [lindex $g 0]}
                }
            }
        set renderid [lsort -unique $group1st]
    } elseif {$show_switch == 2} {
        set id [molinfo top]
        set renderid [list $id]
    }
    if {$render_obj} {
        set wkdir [file join [pwd] "VCUBE"]
        foreach i $renderid basename [getname {*}$renderid] {
            vc $i
            set outfile ${basename}${suffix}.obj
            render Wavefront [file join $wkdir $outfile]
        }
    } elseif {$optix} {
        render_optix -s $scale -suf $suffix -id $renderid -fps $fps -ani $animate
    } elseif {$ospray} {
        render_ospray -s $scale -suf $suffix -id $renderid -fps $fps -ani $animate
    } else {
        render_tachyon -s $scale -suf $suffix -id $renderid -fps $fps -ani $animate
    }
}


proc ::vcube::vrenders {args} {
    # render current scene
    # -n set name
    # -s set scale
    # -preview turn on the preview mode
    # todo optx and ospay update
    global tcl_platform
    set i 0 
    set filename "current"
    set scale 3
    set preview_mode 0
    set silent_flag ""
    foreach j $args {
        incr i 
        if {[string match "-n" $j]} {set filename [lindex $args $i]}
        if {[string match "-s" $j]} {set scale [lindex $args $i]}
        if {[string match "-preview" $j]} {
            set scale 1
            set filename "preview"
            set preview_mode 1
            set silent_flag "-silent"
        }
    }
    global optix
    global ospray
    file mkdir VCUBE
    if {$optix} {
        render_optix $scale $filename "" ""
    } elseif {$ospray} {
        render_ospay $scale $filename "" ""
    } else {
        render_tachyon -s $scale -suf $filename $silent_flag
    }
    if {$preview_mode ==1} {
        set preview_file [file join VCUBE preview.bmp]
        puts $preview_file
        if {$tcl_platform(platform) eq "windows"} {
            exec {*}[auto_execok start]  $preview_file
        }
        if {$tcl_platform(platform) eq "unix"} {
            set run_flag 0
            if {[info exists $image_viewer]} {
                exec $image_viewer $preview_file
            } else {
                set viewer_not_found  1
                foreach com [split $image_viewer] {
                    if { [catch {exec which $com} vprev_com] ==0 } {
                        puts "use $com to view image..." 
                        set viewer_not_found 0
                        exec $com $preview_file
                        break
                    }
                }
                if {$viewer_not_found == 1} {
                    puts "eog or gwenview can not found, could not display image"
                    puts "you can use \"set vprev_com xxx\" to set an available image viewer"
                } 
            }
        }
    }
} 

proc ::vcube::vrenderf {args} {
    # render frames in mol and generate movie  
    # -s set scale
    # -b set begin; -e set end, could use minus number; -step set step
    # -id set id, default top
    # -fps set fps
    # -ani set animate format
    set i 0
    set first 0
    set last -1
    set step 1
    set scale 2
    set id top
    set fps 30
    set animate mp4
    set suffix ""
    foreach j $args {
        incr i 
        if {[string match "-h" $j]} {vhelp vrenderf;return}
        if {[string match "-s" $j]} {set scale [lindex $args $i]}
        if {[string match "-b" $j]} {set first [lindex $args $i]}
        if {[string match "-e" $j]} {set last [lindex $args $i]}
        if {[string match "-step" $j]} {set step [lindex $args $i]}
        if {[string match "-fps" $j]} {set fps [lindex $args $i]}
        if {[string match "-id" $j]} {set id [lindex $args $i]}
        if {[string match "-ani*" $j]} {set animate [lindex $args $i]}
    }
    global optix
    global ospray
    file mkdir VCUBE
    set ses "$first $last $step"
    set idlist [parseid {*}$id]
    if {$optix} {
        render_optix -s $scale -suf $suffix -ses $ses -id $idlist -fps $fps -ani $animate
    } elseif {$ospray} {
        render_ospray -s $scale -suf $suffix -ses $ses -id $idlist -fps $fps -ani $animate
    } else {
        render_tachyon -s $scale -suf $suffix -ses $ses -id $idlist -fps $fps -ani $animate
    }
} 
    
namespace import ::vcube::*
user add key a {::vcube::Vnav_mol p}
user add key d {::vcube::Vnav_mol n}
user add key w {::vcube::Vnav_mol P}
user add key s {::vcube::Vnav_mol N}
user add key q {::vcube::Vnav_iso n}
user add key e {::vcube::Vnav_iso p}
user add key Home {::vcube::Vnav_alpha n}
user add key End {::vcube::Vnav_alpha p}
user add key Insert {::vcube::Vnav_cscale n}
user add key Delete {::vcube::Vnav_cscale p}
user add key Up {::vcube::Vnav_mscale u}
user add key Down {::vcube::Vnav_mscale d}
user add key Left {::vcube::Vnav_mscale l}
user add key Right {::vcube::Vnav_mscale r}
user add key Page_Up {::vcube::Vnav_style p}
user add key Page_Down {::vcube::Vnav_style n}
user add key f {::vcube::Vglobal_switch}
user add key g {::vcube::Vshow_switch}
user add key v {::vcube::vrenders -preview}
