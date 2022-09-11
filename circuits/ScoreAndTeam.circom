pragma circom 2.0.3;

include "../node_modules/circomlib/circuits/comparators.circom";
include "../node_modules/circomlib/circuits/poseidon.circom";

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

template PoseidonTree(nLeafs) {
    signal input in[nLeafs];
    signal output out;

    component poseidon[nLeafs\7];

    var idx = 0;

    // level 1
    for (var i=0; i<nLeafs; i+=8) {
        poseidon[idx] = Poseidon(8);
        for (var j=0; j<8; j++) {
            poseidon[idx].inputs[j] <== in[i+j];
        }
        idx++;
    }
    
    // levels 2
    
    for (var level=2; (nLeafs>>(level*3)) > 0; level++) {
        for (var i=0; i<(nLeafs>>(level*3)); i++) {
            poseidon[idx] = Poseidon(8);
            for (var j=0; j<8; j++) {
                //hard coding or level 2 
               poseidon[idx].inputs[j] <== poseidon[idx-(nLeafs >>(level -1)*3)+i+j].out;     
            // poseidon[idx].inputs[j] <== poseidon[idx-(nLeafs>>((level-1)*2))+i+j].out;     
            }
            idx++;
        }
    }
    
    out <== poseidon[idx-1].out;
}

template ScoreAndTeam () {
    signal input playersScoreInMatch[60];
    signal input decimal;
    signal input selectedPlayerIdentifier;
    signal input matchIdentifier;
    signal input secretIdentity;
    signal input team[60][2];
    signal output myTeamScore;
    signal output myTeamHash;

    signal  totalCalculatedScore;

    component poseidon = PoseidonTree(64);
    for(var i=0;i<60;i++){
        poseidon.in[(i)] <-- team[i][0] + team[i][1];
    }
    poseidon.in[60] <-- decimal;
    poseidon.in[61] <-- selectedPlayerIdentifier;
    poseidon.in[62] <-- matchIdentifier;
    poseidon.in[63] <-- secretIdentity;

    log(poseidon.out);
    myTeamHash <== poseidon.out;

    component checkEqual[60];
   
    component myTeamTotalScore = Sum(60);
    for(var i=0 ; i<60 ; i++){
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

component main { public [ playersScoreInMatch] } = ScoreAndTeam();

/* INPUT = {
    "a": "5",
    "b": "77"
} */