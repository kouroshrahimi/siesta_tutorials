echo "Convergence of MeshCutoff"

MPIRUN="mpirun -n 4"
SIESTA="siesta"
MESHCUTOFFLIST=$(seq 40 10 70)

rm -rf energy_vs_meshcutoff
echo "meshcutoff total_energy" >> energy_vs_meshcutoff

rm -rf outputs
mkdir outputs
cd outputs

for MESHCUTOFF in $MESHCUTOFFLIST
do
	echo "set 'MeshCutoff' = "$MESHCUTOFF "Ry"
	mkdir meshcutoff-$MESHCUTOFF
	cd meshcutoff-$MESHCUTOFF
	cat > meshcutoff-$MESHCUTOFF.fdf<< EOF
SystemName          MeshCutoff convergence for g-ZnO
SystemLabel         g-ZnO           

NumberOfAtoms       2
NumberOfSpecies     2

%block Chemical_Species_label
1 30 ../../Zn-gga
2 8  ../../O-gga
%endblock Chemical_Species_label

LatticeConstant 1.0 Ang

%block LatticeParameters
3.30976 3.30976 20. 90. 90. 120.
%endblock LatticeParameters

AtomicCoordinatesFormat Fractional
%block  AtomicCoordinatesAndAtomicSpecies
0.333333      0.666667      0.500000 1 Zn
0.666667      0.333333      0.500000 2 O
%endblock  AtomicCoordinatesAndAtomicSpecies

%block kgrid_Monkhorst_Pack
   8   0   0  0.0
   0   8   0  0.0
   0   0   1  0.0
%endblock kgrid_Monkhorst_Pack

MeshCutoff          $MESHCUTOFF Ry
PAO.BasisSize       DZP
XC.functional       GGA
XC.authors          PBE
SCF.H.Tolerance     0.00001 eV
EOF

	$MPIRUN $SIESTA <meshcutoff-$MESHCUTOFF.fdf > meshcutoff-$MESHCUTOFF.out
    
    total_energy=$(grep -a "siesta:         Total =" meshcutoff-$MESHCUTOFF.out | awk '{print $4}' )
    mv meshcutoff-$MESHCUTOFF.out ../meshcutoff-$MESHCUTOFF.out
	cd ../
	rm -rf meshcutoff-$MESHCUTOFF

	echo $MESHCUTOFF $total_energy >> ../energy_vs_meshcutoff
done 
cd ../

gnuplot -persist -e "set xlabel 'MeshCutoff (Ry)'; set ylabel 'Total energy (eV)'; p 'energy_vs_meshcutoff' u 1:2 w linespoints"
gnuplot -e "set terminal png; set output 'energy_vs_meshcutoff.png'; set xlabel 'MeshCutoff (Ry)'; set ylabel 'Total energy (eV)'; p 'energy_vs_meshcutoff' u 1:2 w linespoints"

rm -rf *.nc *.xml *.ion
echo "COMPLETED"
