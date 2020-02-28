echo "Convergence of MeshCutoff"

MPIRUN="mpirun -n 4"
SIESTA="siesta"
KPOINTLIST=$(seq 4 1 7)

rm -rf energy_vs_kpoint
echo "k total_energy" >> energy_vs_kpoint

rm -rf outputs
mkdir outputs
cd outputs

for K in $KPOINTLIST
do
	echo "set 'K' = "$K
	mkdir k-$K
	cd k-$K
	cat > k-$K.fdf<< EOF
SystemName          kpoint convergence for g-ZnO
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
   $K   0    0  0.0
   0    $K   0  0.0
   0    0    1  0.0
%endblock kgrid_Monkhorst_Pack

MeshCutoff          100 Ry
PAO.BasisSize       DZP
XC.functional       GGA
XC.authors          PBE
SCF.H.Tolerance     0.00001 eV
EOF

	$MPIRUN $SIESTA <k-$K.fdf > k-$K.out
    
    total_energy=$(grep -a "siesta:         Total =" k-$K.out | awk '{print $4}' )
    mv k-$K.out ../k-$K.out
	cd ../
	rm -rf k-$K

	echo $K $total_energy >> ../energy_vs_kpoint
done 
cd ../

gnuplot -persist -e "set xlabel 'k'; set ylabel 'Total energy (eV)'; p 'energy_vs_kpoint' u 1:2 w linespoints"
gnuplot -e "set terminal png; set output 'energy_vs_kpoint.png'; set xlabel 'k'; set ylabel 'Total energy (eV)'; p 'energy_vs_kpoint' u 1:2 w linespoints"

rm -rf *.nc *.xml *.ion
echo "COMPLETED"
