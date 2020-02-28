echo "Convergence of LatticeConstant"

MPIRUN="mpirun -n 4"
SIESTA="siesta"
LATTICECONSTANTLIST=$(seq 2 0.25 5)

rm -rf energy_vs_LatticeConstant
echo "LatticeConstant total_energy" >> energy_vs_LatticeConstant

rm -rf outputs
mkdir outputs
cd outputs

for LATTICECONSTANT in $LATTICECONSTANTLIST
do
	echo "set 'LatticeConstant' = "$LATTICECONSTANT "Ang"
	mkdir LatticeConstant-$LATTICECONSTANT
	cd LatticeConstant-$LATTICECONSTANT
	cat > LatticeConstant-$LATTICECONSTANT.fdf<< EOF
SystemName          LatticeConstant convergence for AgI molecule
SystemLabel         AgI           

NumberOfAtoms       2
NumberOfSpecies     2

%block Chemical_Species_label
1   47  ../../Ag
2   53  ../../I
%endblock Chemical_Species_label

LatticeConstant $LATTICECONSTANT Ang

%block LatticeVectors 
    1.00000    0.00000    0.00000
    0.00000    1.00000    0.00000
    0.00000    0.00000    1.00000
%endblock LatticeVectors

AtomicCoordinatesFormat NotScaledCartesianAng
%block AtomicCoordinatesAndAtomicSpecies
   -0.23280   -0.12659    0.34162	2
    1.04055    0.56587   -1.52678	1
%endblock AtomicCoordinatesAndAtomicSpecies

%block kgrid_Monkhorst_Pack
   4   0   0  0.0
   0   4   0  0.0
   0   0   4  0.0
%endblock kgrid_Monkhorst_Pack

MeshCutoff          50 Ry
PAO.BasisSize       DZP
XC.functional       LDA
XC.authors          CA
SCF.H.Tolerance     0.00001 eV
EOF

	$MPIRUN $SIESTA <LatticeConstant-$LATTICECONSTANT.fdf > LatticeConstant-$LATTICECONSTANT.out
    
    total_energy=$(grep -a "siesta:         Total =" LatticeConstant-$LATTICECONSTANT.out | awk '{print $4}' )
    mv LatticeConstant-$LATTICECONSTANT.out ../LatticeConstant-$LATTICECONSTANT.out
	cd ../
	rm -rf LatticeConstant-$LATTICECONSTANT

	echo $LATTICECONSTANT $total_energy >> ../energy_vs_LatticeConstant
done 
cd ../

gnuplot -persist -e "set xlabel 'LatticeConstant (Ang)'; set ylabel 'Total energy (eV)'; p 'energy_vs_LatticeConstant' u 1:2 w linespoints"
gnuplot -e "set terminal png; set output 'energy_vs_LatticeConstant.png'; set xlabel 'LatticeConstant (Ang)'; set ylabel 'Total energy (eV)'; p 'energy_vs_LatticeConstant' u 1:2 w linespoints"

rm -rf *.nc *.xml *.ion
echo "COMPLETED"
