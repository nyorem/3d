

#include "cuda.h"
#include "cuda_runtime.h"
#include "stdio.h"

#include <iostream>

extern void checkKernelExecution();

struct mappedParticlePointers {
	//particules
	float *x, *y, *z, *vx, *vy, *vz, *fx, *fy, *fz, *m, *im, *r;
	bool *kill;
	//ressorts
	float *k, *Lo, *d, *Fmax;
	unsigned int *id1, *id2;
	bool *killSpring;
};


__global__ void forceConstante(
		float *fx, float *fy, float *fz,
		const int nParticles, 
		const float Fx, const float Fy, const float Fz) {


	int id = blockIdx.x*blockDim.x + threadIdx.x;

	if(id >= nParticles)
		return;

	fx[id] += Fx;
	fy[id] += Fy;
	fz[id] += Fz;
}

__global__ void forceMassiqueConstante(
		float *fx, float *fy, float *fz,
		float *m, 
		const int nParticles, 
		const float mFx, const float mFy, const float mFz) {

	int id = blockIdx.x*blockDim.x + threadIdx.x;

	if(id >= nParticles)
		return;

	float _m = m[id];

	fx[id] += _m*mFx;
	fy[id] += _m*mFy;
	fz[id] += _m*mFz;
}


__global__ void pousseeArchimede(float *x, float *y, float *z, 
		float *fx, float *fy, float *fz,
		float *r,  
		const int nParticles, 
		const float nx, const float ny, const float nz,
		const float rho, const float g) {


	int id = blockIdx.x*blockDim.x + threadIdx.x;

	if(id >= nParticles)
		return;

	float _r = r[id];
	float V = 4/3.0*3.14*_r*_r*_r; 

	fx[id] += -nx*rho*V*g;
	fy[id] += -ny*rho*V*g;
	fz[id] += -nz*rho*V*g;
}

__global__ void frottementFluide(
		float *x, float *y, float *z, 
		float *vx, float *vy, float *vz,
		float *fx, float *fy, float *fz,
		const int nParticles, 
		const float k1, const float k2) {
	
	int id = blockIdx.x*blockDim.x + threadIdx.x;

	if(id >= nParticles)
		return;

	float _vx = vx[id], _vy = vy[id], _vz = vz[id];

	fx[id] += -(k1*_vx + k2*_vx*_vx);
	fy[id] += -(k1*_vy + k2*_vy*_vy);
	fz[id] += -(k1*_vz + k2*_vz*_vz);
}

__global__ void frottementFluideAvance(
		float *x, float *y, float *z, 
		float *vx, float *vy, float *vz,
		float *fx, float *fy, float *fz,
		float *r,
		const int nParticles, 
		const float rho, 
		const float cx, const float cy, const float cz) {
	
	int id = blockIdx.x*blockDim.x + threadIdx.x;

	if(id >= nParticles)
		return;

	float _r = r[id];
	float _vx = vx[id], _vy = vy[id], _vz = vz[id];
	float _v = _vx*_vx + _vy*_vy + _vz*_vz;
	float _v2 = _v*_v;

	float S = 4*3.14*_r*_r;

	//F = cx * 1/2 rho v^2 S
	fx[id] -= _vx* 1.0f/2.0f * cx * rho * _v2 * S;
	fy[id] -= _vy* 1.0f/2.0f * cy * rho * _v2 * S;
	fz[id] -= _vz* 1.0f/2.0f * cz * rho * _v2 * S;

}

__global__ void attractors(
		float *x, float *y, float *z, 
		float *fx, float *fy, float *fz,
		float *m, 
		const int nParticles, 
		const float dMin, const float dMax, 
		const float C) {
	
	int id = blockIdx.x*blockDim.x + threadIdx.x;

	if(id >= nParticles)
		return;

	float _x = x[id], _y = y[id], _z = z[id];
	float _m1 = m[id];

	float dx, dy, dz, d, d2;
	float _fx=0, _fy=0, _fz=0;
	float _C;

	for(int i = 0; i < nParticles; i++) {
		if(i==id)
			continue;

		dx = x[i] - _x;
		dy = y[i] - _y;
		dz = z[i] - _z;

		d2 = dx*dx + dy*dy + dz*dz;
		d = sqrt(d2);	

		if(d < dMin || d > dMax)
			continue;

		_C = C*_m1*m[i]/d2;
		
		_fx += _C * dx/d;
		_fy += _C * dy/d;
		_fz += _C * dz/d;
	}

	fx[id] += _fx;
	fy[id] += _fy;
	fz[id] += _fz;
}
	
__global__ void dynamicScheme(
		float *x, float *y, float *z,
		float *vx, float *vy, float *vz,
		float *fx, float *fy, float *fz,
		float *im,
		float dt,
		unsigned int nParticles) {

	int id = blockIdx.x*blockDim.x + threadIdx.x;
	
	if(id >= nParticles)
		return;

	float inverseMass = im[id];
	
	vx[id] += dt*fx[id]*inverseMass;
	vy[id] += dt*fy[id]*inverseMass;
	vz[id] += dt*fz[id]*inverseMass;
	
	x[id] += vx[id]*dt;
	y[id] += vy[id]*dt;
	z[id] += vz[id]*dt;
	
	fx[id] = 0;
	fy[id] = 0;	
	fz[id] = 0;
}

void forceConstanteKernel(
		const struct mappedParticlePointers *pt, const unsigned int nParticles, 
		const float Fx, const float Fy, const float Fz) {
	
	dim3 blockDim(512,1,1);
	dim3 gridDim(ceil((float)nParticles/512),1,1);

	forceConstante<<<gridDim,blockDim,0,0>>>(
		pt->fx, pt->fy, pt->fz,
		nParticles,
		Fx, Fy, Fz);

	cudaDeviceSynchronize();
	checkKernelExecution();
}

void forceMassiqueConstanteKernel(
		const struct mappedParticlePointers *pt, const unsigned int nParticles, 
		const float mFx, const float mFy, const float mFz) {
	
	dim3 blockDim(512,1,1);
	dim3 gridDim(ceil((float)nParticles/512),1,1);

	forceMassiqueConstante<<<gridDim,blockDim,0,0>>>(
		pt->fx, pt->fy, pt->fz,
		pt->m, 
		nParticles,
		mFx, mFy, mFz);

	cudaDeviceSynchronize();
	checkKernelExecution();
}

void pousseeArchimedeKernel(
		const struct mappedParticlePointers *pt, const unsigned int nParticles, 
		const float nx, const float ny, const float nz, 
		const float rho, const float g) {
	
	dim3 blockDim(512,1,1);
	dim3 gridDim(ceil((float)nParticles/512),1,1);

	pousseeArchimede<<<gridDim,blockDim,0,0>>>(
		pt->x, pt->y, pt->z, 
		pt->fx, pt->fy, pt->fz,
		pt->r,  
		nParticles,
		nx, ny, nz,
		rho, g);

	cudaDeviceSynchronize();
	checkKernelExecution();
}

void frottementFluideKernel(
		const struct mappedParticlePointers *pt, const unsigned int nParticles, 
		const float k1, const float k2) {

	dim3 blockDim(512,1,1);
	dim3 gridDim(ceil((float)nParticles/512),1,1);

	frottementFluide<<<gridDim,blockDim,0,0>>>(
		pt->x, pt->y, pt->z, 
		pt->vx, pt->vy, pt->vz,
		pt->fx, pt->fy, pt->fz,
		nParticles, 
		k1, k2);
	
	cudaDeviceSynchronize();
	checkKernelExecution();
}

void frottementFluideAvanceKernel(
		const struct mappedParticlePointers *pt, const unsigned int nParticles, 
		const float rho, 
		const float cx, const float cy, const float cz) {

	dim3 blockDim(512,1,1);
	dim3 gridDim(ceil((float)nParticles/512),1,1);

	frottementFluideAvance<<<gridDim,blockDim,0,0>>>(
		pt->x, pt->y, pt->z, 
		pt->vx, pt->vy, pt->vz,
		pt->fx, pt->fy, pt->fz,
		pt->r,
		nParticles, 
		rho,
		cx, cy, cz);
	
	cudaDeviceSynchronize();
	checkKernelExecution();
}

void dynamicSchemeKernel(const struct mappedParticlePointers *pt, unsigned int nParticles) { 
	dim3 blockDim(512,1,1);
	dim3 gridDim(ceil((float)nParticles/512),1,1);

	float dt = 0.01;

	dynamicScheme<<<gridDim,blockDim,0,0>>>(
		pt->x, pt->y, pt->z, 
		pt->vx, pt->vy, pt->vz,
		pt->fx, pt->fy, pt->fz,
		pt->im, dt, nParticles);

	cudaDeviceSynchronize();
	checkKernelExecution();
}

void attractorKernel(const struct mappedParticlePointers *pt, 
		const unsigned int nParticles,
		const float dMin, const float dMax, const float C) { 

	dim3 blockDim(512,1,1);
	dim3 gridDim(ceil((float)nParticles/512),1,1);

	attractors<<<gridDim,blockDim,0,0>>>(
		pt->x, pt->y, pt->z, 
		pt->fx, pt->fy, pt->fz,
		pt->m, 
		nParticles,
		dMin, dMax, C);

	cudaDeviceSynchronize();
	checkKernelExecution();
}
