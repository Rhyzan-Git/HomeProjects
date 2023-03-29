//Arduino Nano pin out. Rework needed.... (Wire A7 on PCB to A3 on Nano) (Wire A6 on PCB to A2 on Nano)
const int rs = 11;    // Pin D11 on Nano, Pin 4 (rs) on LCD
const int en = 10;    // Pin D10 on Nano, Pin 6 (en) on LCD
const int d4 = 17;    // Pin A3 on Nano, Pin 11 (d4) on LCD
const int d5 = 16;    // Pin A2 on Nano, Pin 12 (d5) on LCD
const int d6 = 19;    // Pin A5 on Nano, Pin 13 (d6) on LCD
const int d7 = 18;    // Pin A4 on Nano, Pin 14 (d7) on LCD

//Physical pins to Nano
byte rowPins[ROWS] = {2, 3, 4, 5}; 
byte colPins[COLS] = {6, 7, 8, 9}; 

randomSeed(analogRead(0));   //D14(A0) on Nano




//------------------------------------------------------------------------------
//Libraries
#include <LiquidCrystal.h>
#include <Key.h>
#include <Keypad.h>
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Initialize the library by associating any needed LCD interface pin
// with the arduino pin number it is connected to
const int rs = 13;    // Pin 13 on Arduino, Pin 4 (rs) on LCD
const int en = 12;    // Pin 12 on Arduino, Pin 6 (en) on LCD
const int d4 = 15;    // Pin A1 on Arduino, Pin 11 (d4) on LCD
const int d5 = 16;    // Pin A2 on Arduino, Pin 12 (d5) on LCD
const int d6 = 11;    // Pin 11 on Arduino, Pin 13 (d6) on LCD
const int d7 = 10;    // Pin 10 on Arduino, Pin 14 (d7) on LCD

LiquidCrystal lcd(rs, en, d4, d5, d6, d7);

char buffer1[17] = "";                //Formatting buffer to display to the LCD
char buffer2[17] = "";                //Formatting buffer to display to the LCD
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//Initialize the Keypad Library
//Keypad reserved bytes
const byte ROWS = 4; 
const byte COLS = 4; 

//Keypad characters (In grid form)
char hexaKeys[ROWS][COLS] = {
  {'1', '2', '3', 'A'},
  {'4', '5', '6', 'B'},
  {'7', '8', '9', 'C'},
  {'*', '0', '#', 'D'}
};

//Physical pins to Arduino
byte rowPins[ROWS] = {9, 8, 7, 6}; 
byte colPins[COLS] = {5, 4, 3, 2}; 

//Used to read key press - char customKey = customKeypad.getKey();
Keypad customKeypad = Keypad(makeKeymap(hexaKeys), rowPins, colPins, ROWS, COLS);
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//Setup values
long randNumber = 0;          //Random number rolled to be displayed
long diceFaces = 0;        //Number of dice faces, after being converted from the array
long diceNumber = 0;       //Number of dice, after being converted from the array  
int selectFaces = 0;      //Indicates 'd' has been pressed and the user is inputting number of faces
int facesArray[3];        //3 digit array for dice faces
int numberArray[2];       //2 digit array for dice amount
int slow = 0;             //Slows rolling animation

//------------------------------------------------------------------------------
//Custom characters https://maxpromer.github.io/LCD-Character-Creator/
byte D1Animation[8] = {B11000,B11000,B00000,B00000,B00000,B00000,B00000,B00000};  //1st
byte D2Animation[8] = {B01100,B01100,B00000,B00000,B00000,B00000,B00000,B00000};  //2nd
byte D3Animation[8] = {B00000,B00110,B00110,B00000,B00000,B00000,B00000,B00000};  //3rd
byte D4Animation[8] = {B00000,B00000,B00000,B00011,B00011,B00000,B00000,B00000};  //
byte D5Animation[8] = {B00000,B00000,B00000,B00000,B00001,B00001,B00000,B00000};  //
byte D6Animation[8] = {B00000,B00000,B00000,B00000,B10000,B10000,B00000,B00000};  //
byte D7Animation[8] = {B00000,B00000,B00000,B00000,B00000,B11000,B11000,B00000};  //
byte D8Animation[8] = {B00000,B00000,B00000,B00000,B00000,B00000,B01100,B01100};  //
byte D9Animation[8] = {
byte D10Animation[8] = {
byte D11Animation[8] = {
byte D12Animation[8] = {  
byte D13Animation[8] = {  

//------------------------------------------------------------------------------
//Functions

void callAnimationSwitch(int x){
    switch (x){
      case 0:
        lcd.setCursor(7,1);
        lcd.write(1)
      case 1:
        lcd.setCursor(7, 1);
        lcd.write(2);
        break;
      case 2:
        lcd.setCursor(7, 1);
        lcd.write(3);
        break;
      case 3:
        lcd.setCursor(7, 1);
        lcd.write(4);
        break;
      case 4:
        lcd.setCursor(7, 1);
        lcd.write(5);
        break;
      case 5:
        lcd.setCursor(7, 1);
        lcd.write(6);
        break;
      case 6:
        lcd.setCursor(7, 1);
        lcd.write(7);
        break;
      case 7:
        lcd.setCursor(7, 1);
        lcd.write(8);
        break;
      case 8:
        lcd.setCursor(7, 1);
        lcd.write(9);
        break;
      case 9:
        lcd.setCursor(7, 1);
        lcd.write(10);
        break;
      case 10:
        lcd.setCursor(7, 1);
        lcd.write(11);
        break;
      case 11:
        lcd.setCursor(7, 1);
        lcd.write(12);
        break;
      case 12:
        lcd.setCursor(7, 1);
        lcd.write(13);
        break;   
      case 13:
        lcd.setCursor(7, 1);
        lcd.write(14);
        break;                         
    default:
    return;
    }      
return;
}    

void callBuffer1(){
  lcd.setCursor(0, 0);
  //Prints both Arrays into a buffer to be displayed to the LCD
  sprintf(buffer1, "Selected: %1d%1dd%1d%1d%1d%\n", numberArray[1],numberArray[0],facesArray[2],facesArray[1],facesArray[0]);
  lcd.print(buffer1);
  return;
}

void callBuffer2(){
  lcd.setCursor(0, 1);
  sprintf(buffer2, "Rolled:    %5ld\n", randNumber);
  lcd.print(buffer2);
  return;
}

//Populates the Arrays with dice amounts/faces
void callArray(int x){
  //Shifts selected dice numbers in from right to left
  if (selectFaces == 0){
    numberArray[1] = numberArray[0];
    numberArray[0] = x;
  }
    //Shifts selected dice faces in from right to left
    else{
    facesArray[2] = facesArray[1];
    facesArray[1] = facesArray[0];
    facesArray[0] = x;
    }
  callBuffer1();
  return;    
}

//Resets all values back to default
void callGlobalClear(){
  diceFaces = 0;
  diceNumber = 0;
  selectFaces = 0;
  for (int i = 0; i < 3; i++){
    facesArray[i] = 0;
  }
  for (int i = 0; i < 2; i++){
    numberArray[i] = 0;
  }

  //Updates LCD with cleared info
  callBuffer1();
  randNumber = 0;
  callBuffer2();
  return;
}

//Converts array into long integer
void callConvertArray(){
  int numberD = 0;
  int numberF = 0;
  numberD = (numberArray[1]*10) + numberArray[0];
  diceNumber = numberD;
  numberF = (facesArray[2]*100) + (facesArray[1]*10) + facesArray[0];
  diceFaces = numberF;
  return;
}

void callArrayPreset(int a, int b, int c, int d, int e){
  numberArray[0] = b;
  numberArray[1] = a;
  facesArray[0] = e;
  facesArray[1] = d;
  facesArray[2] = c;
  selectFaces == 0;
  return;
}

void callNumberRoll(){
    //Number animation when rolling
    for (int i = 0; i < 14; i++){
      randNumber = random(1 * diceNumber, diceNumber * diceFaces + 1);
      //Serial.println(randNumber);
      callBuffer2();
      callAnimationSwitch(i);
      delay(50 + slow);
      slow = slow + 2*i;
    }
    //Resets
    selectFaces = 0;
    slow = 0;
    
    return;
}
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
void setup(){
  Serial.begin(9600);
  randomSeed(analogRead(0));
  
  // set up the LCD's number of columns and rows:
  lcd.begin(16, 2);
  
  //Create customer characters
  lcd.createChar(1,D1Animation);
  lcd.createChar(2,D2Animation);
  lcd.createChar(3,D3Animation);
  lcd.createChar(4,D4Animation);
  lcd.createChar(5,D5Animation);
  lcd.createChar(6,D6Animation);
  lcd.createChar(7,D7Animation);
  lcd.createChar(8,D8Animation);          
  callGlobalClear();
}
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
void loop(){
  
  char customKey = customKeypad.getKey();

switch(customKey) {
   
  case 'A':
    callArrayPreset(0,1,0,2,0);
    callBuffer1();
    break;
    
  case 'B':
    callArrayPreset(0,1,0,0,8);
    callBuffer1();
    break; 

  case 'C':
    callArrayPreset(0,1,0,0,6);
    callBuffer1();
    break;

  case 'D':
    if (selectFaces == 0){
      selectFaces = 1;
    }
      else {
        selectFaces = 0;
      }
    break;

  case '*':
    callGlobalClear();
    break;

  case '#':
    //Convert Arrays into integers
    callConvertArray();
    callNumberRoll();
    break;    
    
  case '0':
    callArray(0);
    break;
    
  case '1':
    callArray(1);
    break;
    
  case '2':
    callArray(2);
    break;
  
  case '3':
    callArray(3);
    break;  

  case '4':
    callArray(4);
    break;
    
  case '5':
    callArray(5);
    break;
    
  case '6':
    callArray(6);
    break;

  case '7':
    callArray(7);
    break;  

  case '8':
    callArray(8);
    break;

  case '9':
    callArray(9);
    break;
  
  default:
    //Do nothing...
    return;
}

delay(10);
}

//------------------------------------------------------------------------------
