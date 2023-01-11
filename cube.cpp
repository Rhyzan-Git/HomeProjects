//Layer pins (ENABLE ONE AT A TIME)
#define Layer0 13
#define Layer1 12
#define Layer2 8
#define Layer3 7
#define Layer4 4

//Anode pins (ENABLE ONE AT A TIME)
#define Anode0 2
#define Anode1 14
#define Anode2 15
#define Anode3 16
#define Anode4 17

//Cathode pins (ENABLE DESIRED LEDS)
#define Cathode0 11
#define Cathode1 10
#define Cathode2 9
#define Cathode3 6
#define Cathode4 5

//Initialized values
int layer = 0;            			//Selects the layer (0-4)
int anode = 0;          			//Selects the Anode (0-4)
//LED Address 0 = Layer, 1 = Column, 2-6 = Row
int LEDAddress[6] = {0, 0, 0, 0, 0, 0}; 		

void enLayer(int z){
  switch(z){
    case '0':
      digitalWrite(Layer0, HIGH);
      digitalWrite(Layer1, LOW);
      digitalWrite(Layer2, LOW);
      digitalWrite(Layer3, LOW);
      digitalWrite(Layer4, LOW);
      break;
    case '1':
      digitalWrite(Layer0, LOW);
      digitalWrite(Layer1, HIGH);
      digitalWrite(Layer2, LOW);
      digitalWrite(Layer3, LOW);
      digitalWrite(Layer4, LOW);
      break;
    case '2':
      digitalWrite(Layer0, LOW);
      digitalWrite(Layer1, LOW);
      digitalWrite(Layer2, HIGH);
      digitalWrite(Layer3, LOW);
      digitalWrite(Layer4, LOW);
      break;
    case '3':
      digitalWrite(Layer0, LOW);
      digitalWrite(Layer1, LOW);
      digitalWrite(Layer2, LOW);
      digitalWrite(Layer3, HIGH);
      digitalWrite(Layer4, LOW);
      break;
    case '4':
      digitalWrite(Layer0, LOW);
      digitalWrite(Layer1, LOW);
      digitalWrite(Layer2, LOW);
      digitalWrite(Layer3, LOW);
      digitalWrite(Layer4, HIGH);
      break;
    default:
      digitalWrite(Layer0, LOW);
      digitalWrite(Layer1, LOW);
      digitalWrite(Layer2, LOW);
      digitalWrite(Layer3, LOW);
      digitalWrite(Layer4, LOW);
  }
  return;
}

void enAnode(int x){
    switch(x){
      case '0':
        digitalWrite(Anode0, HIGH);
        digitalWrite(Anode1, LOW);
        digitalWrite(Anode2, LOW);
        digitalWrite(Anode3, LOW);
        digitalWrite(Anode4, LOW);
        break;
      case '1':
        digitalWrite(Anode0, LOW);
        digitalWrite(Anode1, HIGH);
        digitalWrite(Anode2, LOW);
        digitalWrite(Anode3, LOW);
        digitalWrite(Anode4, LOW);
        break;
      case '2':
        digitalWrite(Anode0, LOW);
        digitalWrite(Anode1, LOW);
        digitalWrite(Anode2, HIGH);
        digitalWrite(Anode3, LOW);
        digitalWrite(Anode4, LOW);
        break;
      case '3':
        digitalWrite(Anode0, LOW);
        digitalWrite(Anode1, LOW);
        digitalWrite(Anode2, LOW);
        digitalWrite(Anode3, HIGH);
        digitalWrite(Anode4, LOW);
        break;
      case '4':
        digitalWrite(Anode0, LOW);
        digitalWrite(Anode1, LOW);
        digitalWrite(Anode2, LOW);
        digitalWrite(Anode3, LOW);
        digitalWrite(Anode4, HIGH);
        break;
      default:
        digitalWrite(Anode0, LOW);
        digitalWrite(Anode1, LOW);
        digitalWrite(Anode2, LOW);
        digitalWrite(Anode3, LOW);
        digitalWrite(Anode4, LOW);
    }
  return;
}

void enLED(int address[]){
	enLayer(address[0]);
	enAnode(address[1]);
	if (address[2] == '1'){ digitalWrite(Cathode0, HIGH); }
		else { digitalWrite(Cathode0, LOW); }
	if (address[3] == '1'){ digitalWrite(Cathode1, HIGH); }
		else { digitalWrite(Cathode1, LOW); }
	if (address[4] == '1'){ digitalWrite(Cathode2, HIGH); }
		else { digitalWrite(Cathode2, LOW); }
	if (address[5] == '1'){ digitalWrite(Cathode3, HIGH); }
		else { digitalWrite(Cathode3, LOW); }
	if (address[6] == '1'){ digitalWrite(Cathode4, HIGH); }
		else { digitalWrite(Cathode4, LOW); }

  return;
}

void setup(){
  //Sets defined pins as outputs
  pinMode(Layer0,  OUTPUT);
  pinMode(Layer1,  OUTPUT);
  pinMode(Layer2,  OUTPUT);
  pinMode(Layer3,  OUTPUT);
  pinMode(Layer4,  OUTPUT);
  
  pinMode(Anode0,  OUTPUT);
  pinMode(Anode1,  OUTPUT);
  pinMode(Anode2,  OUTPUT);
  pinMode(Anode3,  OUTPUT);
  pinMode(Anode4,  OUTPUT);
  
  pinMode(Cathode0,  OUTPUT);
  pinMode(Cathode1,  OUTPUT);
  pinMode(Cathode2,  OUTPUT);
  pinMode(Cathode3,  OUTPUT);
  pinMode(Cathode4,  OUTPUT);
}

void loop(){
	while(1){
		
		LEDAddress[0] = 0;	//Layer 0-4
		LEDAddress[1] = 0;	//Column 0-4
		LEDAddress[2] = 0;  //Row 0 = OFF, 1 = ON
		LEDAddress[3] = 0;  //Row 0 = OFF, 1 = ON
		LEDAddress[4] = 0;  //Row 0 = OFF, 1 = ON
		LEDAddress[5] = 0;  //Row 0 = OFF, 1 = ON
		LEDAddress[6] = 0;	//Row 0 = OFF, 1 = ON
		enLED(LEDAddress);	//Call enable LED function
		
		
		
	}
}
