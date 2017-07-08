MidiIn min;
MidiMsg msg;

OscOut osc;
osc.dest("10.10.10.1",6969);
oscOut("/song",[2]);

//IDEAS: 1. drum and bass song
// 2. song where each bd hit triggers fast rhythm that changes
// 3. deerhoof cover
// 4. EVIDENCE - monk : DO THIS FIRST
// 5. morton feldman vibes
// 6. use shakers ugen to trigger random environmental sounds
//7. use voicForm to do crazy shit


0 => int bassindex;
0 => int snareindex;
0 => int tomindex;
0 => int bSection;
0 => int Achordindex;
0 => int Bchordindex;
0 => int globalChordIndex;
0 => int a;


int hitTom;
now=> time tomTime; //had added + 1000::second before, why???
int hitBass;
now  => time bassTime;
int hitSnare;
now => time snareTime;

[["D#1","G2", "A#2", "C3", "D3"], ["G1","A2","A#2","C3","F3"], ["C1", "G2","A#2","C#3","F#3"], 
["F1","G2","G#2","A#2","D#3"], ["D1","E2","F2","G2","C3"],["A#0","F2","G#2","A#2","E3"],
["A1","F#2","G2","B2","C#3"],["G#1","F#2","A#2","B2","F#3"], ["F#1","G#2","A#2","B2","D#3"],
["C#2","G2","A#2","B2","F3"],["C2","G2","A#2","C3","D#3"],["C2","A2","A#2","C3","D#3"], 
["F1","A#2","D#3","F3","A#3"], ["F1","A2","D#3","F#3","B3"]] @=> string AchordStrings[][];
int Achords[AchordStrings.size()][AchordStrings[0].size()]; //all chords have to be same length

[["A#1","C3","C#3","D#3","G#3"], ["D#1", "C3","C#3","F3","A3"], ["G#1","C3","D3","F#3","A#3"], 
["C#1","D#3","F3","G3","B3"],["D1","E3","F3","G3","C4"],["G1","F3","A3","B3","C#4"],
["F1","D#3","G3","A3","D4"],["A#1","D3","G#3","A#3","E4"]] @=> string BchordStrings[][];
int Bchords[BchordStrings.size()][BchordStrings[0].size()]; //all chords have to be same length

for(0 => int i; i<Achords.size(); i++) //convert to MIDI notes
{
    notes2nums(AchordStrings[i],1) @=> Achords[i];
}

for(0 => int i; i<Bchords.size(); i++) //convert to MIDI notes
{
    notes2nums(BchordStrings[i],1) @=> Bchords[i];
}

SawOsc OSCarray[5];
ADSR E[5];
PRCRev R[5];
BiQuad F[5];

for( 0 => int i; i<5; i++)
{   OSCarray[i] => E[i] => R[i] => dac;
    1.0 => OSCarray[i].gain;
    E[i].set(20::ms, 10::ms, .9, 500::ms);
    0.01 => R[i].mix;
    .99 => F[i].prad; 
    1 => F[i].eqzs;
    (6-i)*.01 => F[i].gain;
}


//MIDI port
0 => int port;

if( !min.open(port))
{
    <<<"ERROR: midi port didn't open on port:", port>>>;
    me.exit();
}

spork ~ ddrumTrig();
10::ms => now;
spork ~ ddrumTrig();
10::ms => now;
spork ~ ddrumTrig();
10::ms => now;
spork ~ voiceGate();
10::ms => now;
oscOut("/songSection",[0]);

while(true)
{
    1::second => now;
    if(((globalChordIndex - 2) % 4) == 0) 
    {
        oscOut("/songSection",[1]);
        1 => bSection;
    }
    else
    {
        oscOut("/songSection",[0]);
        0 => bSection;
    }
}

fun void voiceGate()
{
    while(true)
    {
        if(hitTom==1 && (now > tomTime + 300::ms) )
        {
            0 => hitTom;
        }
        if(hitBass==1 && (now > bassTime + 1000::ms) )
        {
            0 => hitBass;
        }
        if(hitSnare==1 && (now > snareTime + 100::ms) )
        {
            0 => hitSnare;
        }
        5::ms => now;
    }
}

fun void ddrumTrig()
{
    while(true)
    {
        min => now;
        <<<(msg.data2)>>>;
        
        while(min.recv(msg))
        {
            //<<< msg.data1, msg.data2, msg.data3 >>>;
            if( msg.data3!=0 && msg.data2 == 36 && hitBass==0) //kick drum
            {
                1 => hitBass; 
                
                for( 0 => int i; i<5; i++)
                { 
                    ((globalChordIndex % 4) + 1) * 350 => a;
                    E[i].set(20::ms, 10::ms, .9, a::ms);
                    
                }
                   
                <<<a>>>;
               
                if(bSection == 0)
                {
                    for(0 => int i; i < Achords[Achordindex].size(); i++)
                    {
                        E[i].keyOff();
                    }
                    
                    oscOut("/chords",[Achords[Achordindex][0]]);
                    
                    for(0 => int i; i < Achords[Achordindex].size(); i++)
                    {
                        
                        Std.mtof(Achords[Achordindex][i]) => OSCarray[i].freq;
                        E[i].keyOn();
                    }
                
                    if(Achordindex == Achords.size()-1) globalChordIndex+1 => globalChordIndex;
                    
                    (Achordindex + 1) % Achords.size() => Achordindex;
                
                
                    100::ms => now;
                
                
                    for(0 => int i; i < Achords[Achordindex].size(); i++)
                    {
                        E[i].keyOff();
                    }
                
                    100::ms => now;    
                }
                else
                {
                    for(0 => int i; i < Bchords[Bchordindex].size(); i++)
                    {
                        E[i].keyOff();
                    }
                    
                    oscOut("/chords",[Bchords[Bchordindex][0]]);
                    
                    for(0 => int i; i < Bchords[Bchordindex].size(); i++)
                    {
                        
                        Std.mtof(Bchords[Bchordindex][i]) => OSCarray[i].freq;
                        E[i].keyOn();
                    }
                    
                    if(Bchordindex == Bchords.size()-1) globalChordIndex+1 => globalChordIndex;
                    
                    (Bchordindex + 1) % Bchords.size() => Bchordindex;
                    
                    
                    100::ms => now;
                    
                    
                    for(0 => int i; i < Bchords[Bchordindex].size(); i++)
                    {
                        E[i].keyOff();
                    }
                    
                    100::ms => now;  
                    
                }
              
            }   
        }
    }    
}


///UTIL FUNCTIONS///

function int[] notes2nums(string notes[], int numcopies)
{
    ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"] @=> string A[];
    string numTOnote[127];
    int noteTOnum[127];
    
    //create array of midi notes indexed by integers 0-127
    for(0 => int i; i<127;i++)
    {
        i % 12 => int mod;
        -2 + i/12 => int counter;
        A[mod] + counter => numTOnote[i];
    }
    
    //create array indexed by midi notes (the inverse of B)
    for(0 => int i; i<127; i++)
    {
        i => noteTOnum[numTOnote[i]];
    }
    
    int numbers[notes.size()*numcopies];
    for(0 => int i; i<notes.size()*numcopies;i++)
    {
        i % notes.size() => int index;
        noteTOnum[notes[index]] => numbers[i];
    }
    return numbers;
}

function int[] changeOctave(int noteNums[], string choice, int x)
{
    int result[noteNums.size()];
    
    if(choice == "up")
    {
        for(0 => int i; i < noteNums.size(); i++)
        {
            noteNums[i] + 12*x => result[i];
        }
    }
    else if(choice == "down")
    {
        for(0 => int i; i < noteNums.size(); i++)
        {
            noteNums[i] - 12*x => result[i];
        }
    }
    else
    {
        <<<"ERROR">>>;
    }
    return result;
}

function int[] transpose(int noteNums[], string choice, int halfSteps)
{
    int result[noteNums.size()];
    
    if(choice == "up")
    {
        for(0 => int i; i < noteNums.size(); i++)
        {
            noteNums[i] + halfSteps => result[i];
        }
    }
    else if(choice == "down")
    {
        for(0 => int i; i < noteNums.size(); i++)
        {
            noteNums[i] - halfSteps => result[i];
        }
    }
    else
    {
        <<<"ERROR">>>;
    }
    return result;
}

fun void oscOut(string addr, int val[]){
    osc.start(addr);
    
    for(0 => int i; i<val.size(); i++)
    {
        osc.add(val[i]);
    }
    osc.send();
}