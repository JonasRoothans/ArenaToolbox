T1 = load('Tapproved');
T2 = load('T2022');
Tfake2mni = [-1 0 0 0;0 -1 0 0;0 0 1 0;0 -37.5 0 1];


%leftSTN
arena2mni_leftSTN = T2.arena2mni_leftSTN;
stu2mni_leftSTN = T1.leftstn2mni*Tfake2mni*T2.arena2mni_leftSTN;

%rightSTN
arena2mni_rightSTN = T2.arena2mni_rightSTN;
stu2mni_rightSTN = T1.rightstn2mni*Tfake2mni*arena2mni_rightSTN;

%leftGPi
arena2mni_leftGPI = T2.arena2mni_leftGPI;
stu2mni_leftGPI = T1.leftgpi2mni*Tfake2mni*arena2mni_leftGPI;

%rightGPi
arena2mni_rightGPI = T2.arena2mni_rightGPI;
stu2mni_rightGPI = T1.rightgpi2mni*Tfake2mni*arena2mni_rightGPI;

save('T2022','arena2mni_leftSTN','arena2mni_rightSTN','arena2mni_leftGPI','arena2mni_rightGPI',...
    'stu2mni_leftSTN','stu2mni_rightSTN','stu2mni_leftGPI','stu2mni_rightGPI')