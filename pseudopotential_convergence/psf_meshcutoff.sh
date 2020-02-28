#! /bin/bash

## Check the convergence versus MeshCutoff in SIESTA
## for a single atom with pseudopotential .psf file
## 
## Developed by: Kourosh Rahimi, Ph.D., https://github.com/kouroshrahimi
## Inspired by the code developed by Julen Larrucea julen@larrucea.eu for quantum espresso

## Note: First, make it executable: $ chmod +x psf_meshcutoff.sh

PWD=$(pwd -P )

while getopts f:x:m:l:p:s:h opt
do
   case "$opt" in
      f) PSF_ARG=$OPTARG;;
      x) BIN=$OPTARG;;
      m) MPI=$OPTARG;;
      l) ML=$OPTARG;;
      p) PO="yes";;
      s) SP="yes";;
      h) echo """   Usage:
    -f  Name of the pseudopotential .psf file in current directory
        or path to it.
    -x  path to the siesta binary (if not in the \$PATH)
    -m  MPI driver with options (i.e. "mpirun -np 4")
    -l  MeshCutoff list as "first step last" Ry. e.g. "40 10 200"
    -p  Plot Only. It assumes the calculation is already done previously
    -s  Save picture
    -h  print this help 
   Example: psf_meshcutoff.sh -f ~/pseudos/H.psf -x ~/siesta/Obj/siesta -m "mpirun -np 4" -l "40 10 200"
   Example: psf_meshcutoff.sh -f ~/pseudos/H.psf -x ~/siesta/Obj/siesta -m "mpirun -np 4" -l "40 10 200" -p "yes"
 """
     exit 1  ;;
   esac
done

echo "    psf_meshcutoff.sh  "
echo "    -------------------" 

# Parse PSF file and path
if [ -z "$PSF_ARG" ]; then  
  echo "Provide a pseudopotential .psf file name!"
  exit
else
  PSEUDO_DIR=$( dirname $PSF_ARG )"/"
  PSEUDO=$( basename $PSF_ARG )
  ATOM=$(head -n 1 $PSEUDO | awk '{print $1}')
  TYPE=$(head -n 1 $PSEUDO | awk '{print $2}')
  if [[ "$TYPE" == "ca" ]]; then
  	XCFUNC="LDA"
  	XCAUTH="PZ"
  else
  	XCFUNC="GGA"
  	XCAUTH="PBE"
  fi
  #remove .psf extension from pseudopotential file name
  SP=$( echo $PSEUDO | cut -d"." -f1 )
  #parse element symbol (specie)
  #if [[ ${#SP} -gt "2" ]]; then #parse 1st letter in case of non standard file name
  #  SP=${PSEUDO:0:2} 
  #fi
fi

declare -A ATOMIC_NUMBER=( [H]=1 [He]=2 [Li]=3 [Be]=4 [B]=5 [C]=6 [N]=7 [O]=8 [F]=9 [Ne]=10 [Na]=11 [Mg]=12 [Al]=13 [Si]=14 [P]=15 [S]=16 [Cl]=17 [Ar]=18 [K]=19 [Ca]=20 [Sc]=21 [Ti]=22 [V]=23 [Cr]=24 [Mn]=25 [Fe]=26 [Co]=27 [Ni]=28 [Cu]=29 [Zn]=30 [Ga]=31 [Ge]=32 [As]=33 [Se]=34 [Br]=35 [Kr]=36 [Rb]=37 [Sr]=38 [Y]=39 [Zr]=40 [Nb]=41 [Mo]=42 [Tc]=43 [Ru]=44 [Rh]=45 [Pd]=46 [Ag]=47 [Cd]=48 [In]=49 [Sn]=50 [Sb]=51 [Te]=52 [I]=53 [Xe]=54 [Cs]=55 [Ba]=56 [La]=57 [Ce]=58 [Pr]=59 [Nd]=60 [Pm]=61 [Sm]=62 [Eu]=63 [Gd]=64 [Tb]=65 [Dy]=66 [Ho]=67 [Er]=68 [Tm]=69 [Yb]=70 [Lu]=71 [Hf]=72 [Ta]=73 [W]=74 [Re]=75 [Os]=76 [Ir]=77 [Pt]=78 [Au]=79 [Hg]=80 [Tl]=81 [Pb]=82 [Bi]=83 [Po]=84 [At]=85 [Rn]=86 [Fr]=87 [Ra]=88 [Ac]=89 [Th]=90 [Pa]=91 [U]=92 [Np]=93 [Pu]=94 [Am]=95 [Cm]=96 [Bk]=97 [Cf]=98 [Es]=99 [Fm]=100 [Md]=101 [No]=102 [Lr]=103 [Rf]=104 [Db]=105 [Sg]=106 [Bh]=107 [Hs]=108 [Mt]=109 [Ds]=110 [Rg]=111 )

# Check for SIESTA binary
SIESTA_BIN=`which siesta 2>/dev/null`

if [ "$BIN" ]; then
  SIESTA_BIN=$BIN  
fi

if [ -z "$SIESTA_BIN" ]; then
   echo " # ERROR: Provide a path to a SIESTA binary."
   exit
fi

echo "SIESTA executed as: " $MPI $SIESTA_BIN

# Check for MeshCutoff list input
if [ -z "$ML" ]; then  
  echo 'Provide meshcutoff list as "first step last"'
  exit
else
  meshcutoff_list=$(seq $ML)
fi

echo "meshcutoff list: " $meshcutoff_list



if [[ -z $PO ]]; then    # if PO option present skip this part

rm -f out.meshcutoff.$PSEUDO
for i in $meshcutoff_list; do
 echo "  calculating meshcutoff="$i " ... "

   # Generating a basic SIESTA fdf input
   cat > in << EOF
SystemName                 $PSEUDO convergence test versus meshcutoff 
SystemLabel                $SP

NumberOfSpecies            1
NumberOfAtoms              1

%block ChemicalSpeciesLabel
1   ${ATOMIC_NUMBER[$ATOM]}  $SP
%endblock ChemicalSpeciesLabel
 
%block kgrid_Monkhorst_Pack
1   0   0   0.0
0   1   0   0.0
0   0   1   0.0
%endblock kgrid_Monkhorst_Pack

LatticeConstant 1.0 Ang

%block LatticeParameters 
 20. 20. 20. 90. 90. 90.
%endblock LatticeParameters

AtomicCoordinatesFormat Fractional
%block  AtomicCoordinatesAndAtomicSpecies
0.5      0.5      0.5 1
%endblock  AtomicCoordinatesAndAtomicSpecies

MeshCutoff          $i Ry
XC.functional       $XCFUNC
XC.authors          $XCAUTH
SCF.H.Tolerance     0.00001 eV

EOF
$MPI $SIESTA_BIN < in >> out.meshcutoff.$PSEUDO 2> /dev/null 

done  # loop for calculations

energies=$(grep -a "siesta:         Total =" out.meshcutoff.$PSEUDO | awk '{print $4}' )

# Write total energies obtained at different meshcutoff to energies.meshcutoff.PSEUDO
declare -a array_meshcutoff
declare -a array_ener
array_meshcutoff=(${meshcutoff_list// / })
array_ener=(${energies// / })
rm -f energies.meshcutoff.$PSEUDO
echo "meshcutoff  total_energy" >> energies.meshcutoff.$PSEUDO
for i in `seq 0 ${#array_meshcutoff[@]}`; do
  echo ${array_meshcutoff[$i]} ${array_ener[$i]} >> energies.meshcutoff.$PSEUDO
done

fi # end of PO section


# Plotting results with gnuplot

if [ -f energies.meshcutoff.$PSEUDO ]; then
gnuplot_bin=`which gnuplot 2>/dev/null`
if [ "$gnuplot_bin" != "" ]; then
  $gnuplot_bin -persist -e "set xlabel 'meshcutoff (Ry.)'; set ylabel 'Total energy (eV.)'; p 'energies.meshcutoff.$PSEUDO' u 1:2 w linespoints"
  $gnuplot_bin -e "set terminal png; set output 'fig.meshcutoff.$SP-psf.png'; set xlabel 'Meshcutoff (Ry.)'; set ylabel 'Total energy (eV.)'; p 'energies.meshcutoff.$PSEUDO' u 1:2 w linespoints"
else
  $ECHO "No gnuplot in PATH. Results not plotted."
fi
else
 echo ' ' 
 echo ' # ERROR: There is no energy file (called "energies.ecutwfc.$PSEUDO"). Unable to plot.' 
fi  #end of plot lool

shopt -s extglob
rm -f !(*.psf|*.png|*.sh)

echo " - DONE! -"


