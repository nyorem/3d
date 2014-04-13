#include "particule.h"

Particule::Particule(Vec pos, Vec vel, double m, double r) :
	position(pos),
	velocity(vel),
	mass(m),
	radius(r)
{
	invMass = (m > 0 ? 1 / m : 0.0);
}

Particule::~Particule()
{
}


const Vec & Particule::getPosition() const
{
	return position;
}

const Vec & Particule::getVelocity() const
{
	return velocity;
}

double Particule::getMass() const
{
	return mass;
}

double Particule::getInvMass() const
{
	return invMass;
}

double Particule::getRadius() const
{
	return radius;
}

void Particule::setPosition(const Vec &pos)
{
	position = pos;
}

void Particule::setVelocity(const Vec &vel)
{	
	velocity = vel;
}

void Particule::incrPosition(const Vec &pos)
{
	position += pos;
}

void Particule::incrVelocity(const Vec &vel)
{
	velocity += vel;
}

std::ostream& operator<<(std::ostream& os, const Particule& p)
{
	os << "pos (" << p.getPosition() << "), vel (" << p.getVelocity() << ")";
	return os;
}

