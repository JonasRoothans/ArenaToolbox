# mwwtest
Mann-Whitney-Wilcoxon non parametric test for two unpaired groups.<br/>
This file execute the non parametric Mann-Whitney-Wilcoxon test to evaluate the
difference between unpaired samples. If the number of combinations is less than
20000, the algorithm calculates the exact ranks distribution; else it 
uses a normal distribution approximation. The result is not different from
RANKSUM MatLab function, but there are more output informations.
There is an alternative formulation of this test that yields a statistic
commonly denoted by U. Also the U statistic is computed.

Syntax: 	STATS=MWWTEST(X1,X2)
     
    Inputs:
          X1 and X2 - data vectors. 
    Outputs:
          - T and U values and p-value when exact ranks distribution is used.
          - T and U values, mean, standard deviation, Z value, and p-value when
          normal distribution is used.
       If STATS nargout was specified the results will be stored in the STATS
       struct.

     Example: 

        X1=[181 183 170 173 174 179 172 175 178 176 158 179 180 172 177];

        X2=[168 165 163 175 176 166 163 174 175 173 179 180 176 167 176];

          Calling on Matlab the function: mwwtest(X1,X2)

          Answer is:

MANN-WHITNEY-WILCOXON TEST
 
                       Group_1    Group_2
                       _______    _______

    Numerosity          15         15    
    Sum_of_Rank_W      270        195    
    Mean_Rank           18         13    
    Test_variable_U     75        150    

Sample size is large enough to use the normal distribution approximation
 
    Mean       SD        Z       p_value_one_tail    p_value_two_tails
    _____    ______    ______    ________________    _________________

    112.5    24.047    1.5386    0.061947            0.12389      

          Created by Giuseppe Cardillo
          giuseppe.cardillo-edta@poste.it

To cite this file, this would be an appropriate format:
Cardillo G. (2009). MWWTEST: Mann-Whitney-Wilcoxon non parametric test for two unpaired samples.
http://www.mathworks.com/matlabcentral/fileexchange/25830

