var a g mc mrs n pie r rw winf y;
varexo e_a e_g e_lam e_ms;

parameters invsig delta gam rho gampie gamy rhoa rhog bet 
    	   thetabig omega eps;

eps=6;
thetabig=2;
bet=0.99;
invsig=2.5;
gampie=1.5;
gamy=0.125;
gam=1;
delta=0.36;
omega=0.54;
rhoa=0.5;
rhog=0.5;
rho=0.5;


model(linear);
	y=y(+1)-(1/invsig)*(r-pie(+1)+g(+1)-g);
	y=a+(1-delta)*n;
	mc=rw+n-y;
	mrs=invsig*y+gam*n-g;
	r=rho*r(-1)+(1-rho)*(gampie*pie+gamy*y)+e_ms;
	rw=rw(-1)+winf-pie;
	a=rhoa*a(-1)+e_a;
	g=rhog*g(-1)+e_g;
	rw=mrs;

	// HYBRID PHILLIPS CURVED USED FOR THE SUMULATIONS:
	pie = (omega/(1+omega*bet))*pie(-1)+(bet/(1+omega*bet))*pie(1)+(1-delta)*
      	(1-(1-1/thetabig)*bet)*(1-(1-1/thetabig))/((1-1/thetabig)*(1+delta*(eps-1)))/(1+omega*bet)*(mc+e_lam);

	// FORWARD LOOKING PHILLIPS CURVE:
	// pie=bet*pie(+1)+(1-delta)*(1-(1-1/thetabig)*bet)*(1-(1-1/thetabig))/((1-1/thetabig)*(1+delta*(eps-1)))*(mc+e_lam);
end;

shocks;
var e_a; stderr 1;
var e_g; stderr 1;
var e_ms; stderr 1;
var e_lam; stderr 1;
end;

steady;
check;

stoch_simul(periods=500,irf=0,simul_seed=3);
datatomfile('datarabanal_hybrid',[]);