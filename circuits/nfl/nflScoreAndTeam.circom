pragma circom 2.0.3;

include "../../node_modules/circomlib/circuits/comparators.circom";
include "../../node_modules/circomlib/circuits/poseidon.circom";

// Max number of player in nfl team squad is 53
// Total number of players to pick from 53*2 = 106 (input data)
// If a player is picked its index value hold non zero integer to indicate it
// for integer dividion use '\'

template Sum(nInputs) {
    signal input in[nInputs];
   
    signal output out;

    signal partialSum[nInputs];
    partialSum[0] <== in[0];
    
    for (var i=1; i<nInputs; i++) {
        partialSum[i] <== partialSum[i-1] + in[i];
    }

    out <== partialSum[nInputs-1];
}

template NFLScoreAndTeam () {
    signal input playersScoreInMatch[106];
    signal input decimal;
    signal input selectedPlayerIdentifier;
    signal input matchIdentifier;
    signal input secretIdentity;
    signal input team[106][2];
    signal output myTeamScore;
    signal output myTeamHash;

    signal  totalCalculatedScore;

    component poseidon = PoseidonTree(125);
    for(var i=0;i<106;i++){
        poseidon.in[(i)] <-- team[i][0] + team[i][1];
    }
    for(var i=106; i<121;i++){
        poseidon.in[(i)] <-- 0;
    }
    poseidon.in[121] <-- decimal;
    poseidon.in[122] <-- selectedPlayerIdentifier;
    poseidon.in[123] <-- matchIdentifier;
    poseidon.in[124] <-- secretIdentity;

    log(poseidon.out);
    myTeamHash <== poseidon.out;

    component checkEqual[106];
   
    component myTeamTotalScore = Sum(106);
    for(var i=0 ; i<106 ; i++){
        checkEqual[i] = IsEqual();
        checkEqual[i].in[0] <== team[i][0];
        checkEqual[i].in[1] <== selectedPlayerIdentifier;
        
        myTeamTotalScore.in[i]  <-- checkEqual[i].out != 1 ? 0 :playersScoreInMatch[i]*team[i][1];
        
    }
 
   // log(myTeamTotalScore.out);
    totalCalculatedScore <-- myTeamTotalScore.out;
   // log(totalCalculatedScore);
    totalCalculatedScore ==> myTeamScore;
    
}


template PoseidonTree(nLeafs) {
    signal input in[nLeafs];
    signal output out;

    component poseidon[125\4]; //125/4 => 31.2 ~= 31 i.e. 31 indexs

    var idx = 0;

    // level 1 will makee group of 5 elements 
    for (var i=0; i<nLeafs; i+=5) {
        poseidon[idx] = Poseidon(5); //each index will store poseidon hash of 5 element 
        for (var j=0; j<5; j++) {
            poseidon[idx].inputs[j] <== in[i+j];
        }
        idx++;
    }
    // Till now poseidon[] will store 25 hash  0-24, now idx=25
     // levels 2
    for(var level=2; (nLeafs\(5**level)) > 0; level++ ){
        for (var i=0; i<(nLeafs\(5**level)); i++) { 
            poseidon[idx] = Poseidon(5);
             for (var j=0; j<5; j++) {
                poseidon[idx].inputs[j] <== poseidon[idx - (nLeafs\(5**(level-1))) +(4*i) + j].out;
             }
             idx++;

        }
    }
   
    
    out <== poseidon[idx-1].out;
}

component main { public [ playersScoreInMatch] } = NFLScoreAndTeam();
