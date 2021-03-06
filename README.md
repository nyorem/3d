
#Graphique 3D

Submarine scene demo in OpenGL and CUDA, featuring :
- [x] Animated bubbles (CUDA particle system, procedural sprites)
- [x] Animated seeweeds (CUDA mass-spring system)
- [x] Animated water (CPU only)
- [x] Procedural terrain and cave (GPU marching cube and procedural marble texture)
- [ ] Animated wildlife
- [ ] Animated diver


Require a CUDA Compute Capability 1.1 and OpenGL 3.3 capable device.


##Screenshots (click to enlarge)

![cave1](http://i.imgur.com/LFbaruf.png)

![cave2](http://i.imgur.com/D1JpAkL.png)

![waves](http://i.imgur.com/j7ZUSQZ.png)

![terrain](http://i.imgur.com/solYgUH.png)


-----

##Compiling:

Everything has been tested with `gcc-4.8` and `gcc-4.9`. 
Other c++0x capable compilers might work as well but have not been tested.

###Required libraries:  

Make sure you have all these libraries installed on your computer :

```
    OpenAL
    ALUT
    OpenGL
    GLEW
    GLUT
    Qt4 (QtCore QtGui QtXml QtOpenGL)
    QGLViewer
    Log4cpp
    CUDA 5.0+ (6.5 preferred)
```


###Using CMake 3.0 or above (preferred method)

```
mkdir build
cd build/
cmake ..
make
```

###Using the Makefile (Linux & Mac)

Edit following variables in `vars.mk` :

- Set `L_QGLVIEWER` to `-lQGLViewer` or `-lqglviewer` to match your QGLViewer library.
- Set `NARCH` to match your device CUDA Compute Capability (minimum 11)

Finally compile with `make release`

##Executing:
- Execute the generated binary (`main` by default) at the root of the projet.
- Hit `<Enter>` to launch animation and enjoy ! 
- You can move around with standard QGLViewer keys.



## Frequent problems

#### Everything seems to be ok but the linker does not find my CUDA libraries ? 

Don't forget to add your CUDA library path after a fresh CUDA Toolkit installation.

On linux, assuming `/usr/local/cuda` is where you installed the CUDA Toolkit, simply edit your `~/.bashrc` and add the following lines :
```
    export PATH=/usr/local/cuda/bin:$PATH
    export LD_LIBRARY_PATH=/usr/local/cuda/lib:/usr/local/cuda/lib64:$LD_LIBRARY_PATH
```

Then reload your `.bashrc` with `. ~/.bashrc`.

Sometimes, an additional step might be needed : `sudo ldconfig`

#### Compilation was successfull but when I launch the binary I get `ERROR  : Kernel launch failed : invalid device function` ?

You most likely set an invalid value to the variable `NARCH` in `vars.mk`.
Check your device CUDA Compute Capability online, it should be minimum 11 (standing for 1.1).
Change `NARCH` according to what your device is capable and recompile from sources.

#### Compilation was successfull but when I launch the binary I get some random segfaults on OpenGL API calls ?
 
 First of all, make sure you have an OpenGL 3.3 capable device and that you are using the NVidia proprietary drivers (mandatory for CUDA). 
 If this is the case, make sure your driver is up to date, as OpenGL implementations are rarely bug free.
 
 
#### I have an OpenGL 3.3 capable device but my OpenGL library seems to be out of date ?

If you're using a Mac you might give up at this step.
If not you can try to update your drivers as a last resort.

## Known bugs

- Some black lines appears when computing the terrain with the fast marching cube.
