# Check convergence of SIESTA pseusopotentials vs. MeshCutoff 
This script automates the convergence of a SIESTA `pseudopotential.psf` versus `MeshCutoff` parameter. A similar code developed by [Julen Larrucea](https://blog.larrucea.eu/checking-optimum-cutoff-qe/) for quantum espresso inspired me to adapt it for SIESTA. The code is self-explanatory. Just make it executable:
```bash
$ chmod +x psf_meshcutoff.sh
```
Then you can see a help on how to use it by:
```bash
$ ./psf_meshcutoff.sh -h
```

The directory [example](example) shows the results produced by the script for `Ag.psf`.


![](results_overview.png)
