//  *****************************************************************************************************************
//  *                                                                                                               *
//  *                                         SpikenzieLabs.com                                                     *
//  *                                                                                                               *
//  *                                     SERIAL <-> MIDI Converter                                                 *
//  *                                                                                                               *
//  *                                                                                                               *
//  *****************************************************************************************************************
//
// BY: MARK DEMERS 
// Jan. 2010
// VERSION: 2D
//
// DESCRIPTION:
// Use to convert serial data into MIDI.
//
// The default serial configuration is 57600 bps 8N1
//
// FUNCTION:
// A. Connect serial device onto computer.
// B. Create virtual Midi port if required. (Mac OS use Audio Midi Setup -> Add IAC Port -> click "online")
// C. Launch converter.
// D. Select serial port
// E. Select Midi Input Port
// F. Select Midi Output Port
// G. Let the applet run in the background, RX and TX will flash with serial data

// 
// Changes for version D:
// uses themidibus v4 vs v3

// PROGRAM:
// Coded in Processing 1.0.9
// Used "themidibus" Library by Severin Smith. URL: http://www.smallbutdigital.com/themidibus.php
// UPDATE:
// On OS X 10.5.8 > (with java update 6) mmj is no longer required and will cause a bug, please de-install it !
// Use on Mac OS 10.4.8 or greater requires "mmj" a java Midi subsystem. URL: http://www.humatic.de/htools/mmj.htm
//
// LEGAL:
// This code is provided as is. No guaranties or warranties are given in any form. It is your responsibilty to 
// determine this codes suitability for your application.

import themidibus.*; 
import processing.serial.*;

MidiBus myBus; // The MidiBus
Serial port;  // Create object from Serial class
//Serial port2; 

String ports[] =  Serial.list();
//String midiport[][] = myBus.availableInputs();
String midiInputs[] = myBus.availableInputs();                // <- Doesn't work without this line ????

String StatusText =  "";
String MainTextLineOne = "";
String MainTextLineTwo = "";
String MainTextLineThree = "";
String MainTextLineFour = "";

    String[] available_outputs = MidiBus.availableOutputs(); //Returns an array of available output devices
        String[] available_inputs = MidiBus.availableInputs(); //Returns an array of available input devices


String Letters =      "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
String LettersLower = "abcdefghijklmnopqrstuvwxyz";

int Bauds[] = {9600, 19200, 31250, 38400, 57600, 115200};

int[] val = new int[3];
int[] buffer  = new int[16];

int state = 1 ;
int SPortCount = 0;
int SerialPortID = 0;
int SerialPortBaudRate = 0;
int MPortCount = 0;
int i = 0;
int channel = 0;
int midistatus = 128;
int pitch = 64;
int velocity = 127;
int midi_inputPORT = 0;
int midi_outputPORT =0;
float RX_flash = 0;
color RX_flashcolor = 0;
color TX_flashcolor = 0;
float TX_flash = 0;
int line_space = 0;
int lineSpacing = 15;

int number = 0;
int value = 90;
int keyselection = 99;

boolean SerPortFlag =  false;
boolean RX_ERROR_FLAG = false;

color flashcolor = color(00, 255, 00);
color flashOFFcolor = color(204, 204, 204);


void setup() {
  size(380, 440);
  textFont(createFont("Arial", 12));
  frameRate(25);
  background(255);

  //  MidiBus.list(); // List all available Midi devices on STDOUT. This will show each device's index and name.

}

void draw() {

  switch(state)
  {
  case 0:                                                      // Running

    if((millis() - RX_flash) > 50)
    {
      RX_flashcolor = flashOFFcolor;
    }

    fill(RX_flashcolor);
    noStroke();
    rect(width-30, height-34, 8, 8);
    TX_activity(false);
    
    break;

  case 1:                                                      // Select serial Port
    updatedisplay();
    selectSerialport();
    break;
    
   case 2:                                                      // Select serial Speed
    updatedisplay();
    selectSerialBoadRate();
    break;

  case 3:                                                      // Select MIDI INPUT Port
    updatedisplay();
    selectMidi_IN_port();
    break;

  case 4:                                                      // Select MIDI OUTPUT Port
    updatedisplay();
    selectMidi_OUT_port();
    break;
  }
}

void TX_activity(boolean SerialTX)                            // Used to flash TX indicator
{

  if(SerialTX){
    TX_flashcolor = flashcolor;
    TX_flash = millis();
  }
  else
  {
    if((millis() - TX_flash) > 100){
      TX_flashcolor = flashOFFcolor;

    }
  }
  fill(TX_flashcolor);
  noStroke();
  rect(width-30, height-21, 8, 8);

}

void serialEvent(Serial port)
{
  int i = 0;
  for(i=0; i < 3; i = i +1)
  {
    int inByte = port.read();
    val[i] = inByte;
    if(i==0 && inByte < 128)                                  // Verify 1st Byte is Status byte
    {
      i=3;
    }
  }

  if(val[0] >= 128)
  {
    myBus.sendMessage(val[0], val[1], val[2]);
    RX_flashcolor = flashcolor;
  }
  else
  {
    RX_flashcolor = color(255,0,0);                            // ERROR ! FLash
  }

  RX_flash = millis();
}

void noteOn(int channel, int pitch, int velocity)             // Receive a noteOn
{
  int midistatus = 0;
  int message = 144;
  midistatus = message | channel;

 // println("Note On: "+midistatus+"-"+pitch+"-"+velocity);   // Un-comment to debug

  TX_activity(true);
  port.write(midistatus);  
  port.write(pitch);
  port.write(velocity);
}

void noteOff(int channel, int pitch, int velocity)             // Receive a noteOff
{
  int midistatus = 0;
  int message = 128;
  midistatus = message | channel;

//  println("Note Off: "+midistatus+"-"+pitch+"-"+velocity);   // Un-comment to debug

  TX_activity(true);
  port.write(midistatus);  
  port.write(pitch);
  port.write(velocity);
}

void controllerChange(int channel, int number, int value)       // Receive a controllerChange
{
  int midistatus = 0;
  int message = 176;
  midistatus = message | channel;

//  println("Controller Change: "+midistatus+"-"+number+"-"+value);   // Un-comment to debug

  TX_activity(true);
  port.write(midistatus);  
  port.write(number);
  port.write(value);
}

void selectSerialport() 
{
  StatusText = "Press the number key that matches your Arduino's serial Port:";
  SPortCount = Serial.list().length;
  if(SPortCount==0)
  {
    StatusText = "ERROR: No serial Ports avaliable";
  }
  else
  {
    fill(0);
    line_space = 0;
    for(i=0; i <Serial.list().length; i=i+1)
    {
      text("Port ["+Letters.charAt(i)+"] :    "+ports[i], 15, 80+(line_space), 600, 350);
     line_space= line_space+lineSpacing;
    }
  }
}

void selectSerialBoadRate() 
{
  StatusText = "Press the letter key that matches your serial port baud rate:";

  fill(0); 
  line_space = 0;  
  for(i=0; i < 6; i=i+1)
    {
      text("Baud rate ["+Letters.charAt(i)+"] :    " + Bauds[i] + " bps ", 15, 80+(line_space), 600, 350);
     line_space= line_space+lineSpacing;
    }
}

void selectMidi_IN_port() 
{
  StatusText = "Press the number key that matches MIDI INPUT Port:";
 // MPortCount = midiport.length;
//    MPortCount = midiInputs.length;
   MPortCount = available_inputs.length;
  if(MPortCount==0)
  {
    StatusText = "ERROR: No MIDI Ports avaliable";
  }
  else
  {
    fill(0);
    line_space = 0;
//    for(i=0; i <midiport.length; i=i+1)
       for(i=0; i <available_inputs.length; i=i+1)
    {
 //     if(midiport[i][1]=="Input" || midiport[i][1]=="Input/Output")
     //      if(midiInputs[i]=="Input" || midiInputs[i]=="Input/Output")
    //  {
 //       text("MIDI Port ["+Letters.charAt(i)+"] :    "+midiport[i][0]+" - "+midiport[i][1], 15, 80+(line_space), 600, 350);
         text("MIDI Port ["+Letters.charAt(i)+"] :    "+available_inputs[i], 15, 80+(line_space), 600, 350);
        line_space= line_space+lineSpacing;
    //  }
    }
  }
}

void selectMidi_OUT_port() 
{
  StatusText = "Press the number key that matches MIDI OUTPUT Port:";
//  MPortCount = midiport.length;
//    MPortCount = attachedOutputs.length();
    
 //   String[] available_outputs = MidiBus.availableOutputs(); //Returns an array of available output devices
    
        MPortCount = available_outputs.length;

  if(MPortCount==0)
  {
    StatusText = "ERROR: No MIDI Ports avaliable";
  }
  else
  {
    fill(0);
    line_space = 0;
//    for(i=0; i <midiport.length; i=i+1)
   for(i=0; i < available_outputs.length; i=i+1)
    {
     // if(midiport[i][1]=="Output" || midiport[i][1]=="Input/Output")
     // {
        text("MIDI Port ["+Letters.charAt(i)+"] :    "+available_outputs[i], 15, 80+(line_space), 600, 350);
        line_space= line_space+lineSpacing;
     // }
    }
  }
}

void updatedisplay()
{
  background(255);
  int fadecolor = 220;

  for (int i = 0; i < 60; i = i+1)                                                       // Top area
  {
    stroke(0, fadecolor, 255);
    line(0, i, width, i);
    fadecolor = fadecolor -2;
  }
  fadecolor=128;
  for (int i = height-40; i < height; i = i+1)                                           // Bottom area
  {
    stroke(0, fadecolor, 255);
    line(0, i, width, i);
    fadecolor = fadecolor + 3;
  }

  fadecolor=50;
  for (int i = height-60; i < height-40; i = i+1)                                         // Upper-Bottom area
  {
    stroke(0, fadecolor, 255);
    line(0, i, width, i);
    fadecolor = fadecolor + 3;
  }

  fill(255);                                                                             // Status Title
  stroke(0);
  text("Status:", 15, height - 45);


  fill(0);                                                                                // Status Text
  stroke(50);
  text(StatusText, 15, height-25, 600, 350);

  if(state == 0)
  {
    text(MainTextLineOne, 15, 100);
    text(MainTextLineTwo, 15, 120);
    text(MainTextLineThree, 15, 140);
    text(MainTextLineFour, 15, 160);
    text("Serial RX", width-85, height-25);
    text("Serial TX", width-85, height-12);

    // RX Flash square
    rect(width-30, height-34, 8, 8);
    
    // TX Flash square
    rect(width-30, height-21, 8, 8);
  }


  textAlign(CENTER);
  fill(255);
  textSize(12);
  text("Serial <> MIDI Converter", (width/2)-(300/2),10,300,20);
  textSize(12);
  text("By Mark Demers - SpikenzieLabs.com", (width/2)-(300/2),35,300,45);
  textAlign(LEFT);
  textSize(12);

}

void keyPressed() {
  decodeLetter();
if ((keyselection != 99) || (keyselection != -1))
{
  
  switch(state)
  {
  case 0:                                                                  // Running
    break;

  case 1:                                                                  // Serial Select

    if((keyselection) <=  (Serial.list().length-1))
    {
      state=2;
      StatusText = ("You are using serial port ["+(keyselection)+"] : "+ports[keyselection]);
      SerialPortID = keyselection;
      //     port = new Serial(this,ports[key-48], 57600);                      // Moved to last step
      //     port.buffer(3);
      //     port.clear();
      MainTextLineOne = ("Serial port ["+(keyselection)+"] : "+ports[keyselection]);
    }
    break;
    
    
   case 2:                                                                  // Serial Speed Select

    if((keyselection) <=  5)
    {
      state=3;
    //  StatusText = ("You are using serial port ["+(keyselection)+"] : "+ports[keyselection]);
      SerialPortBaudRate = keyselection;
      MainTextLineTwo = ("Serial Baud Rate ["+(keyselection)+"] : "+Bauds[keyselection]+ " bps ");
    }
    break;   

  case 3:                                                                  // midi Input Select

    if((keyselection) <=  (available_inputs.length-1))
    {
      state=4;
      StatusText = ("You are using MIDI INPUT port ["+(keyselection)+"] : "+available_inputs[keyselection]);
      midi_inputPORT = (keyselection);
      MainTextLineThree = ("MIDI Input port ["+(keyselection)+"] : "+available_inputs[keyselection]);
      delay(250);
    }
    break;

  case 4:                                                                  // Midi OUTput select

    if((keyselection) <=  (available_outputs.length-1))
    {
      state=0;
      StatusText = ("Converter is running");
      midi_outputPORT = (keyselection);
      //                 Parent             In              Out
      //                   |                |                |
      myBus = new MidiBus(this, midi_inputPORT, midi_outputPORT);
      MainTextLineFour = ("MIDI Output port ["+(keyselection)+"] : "+available_outputs[keyselection]);

      port = new Serial(this,ports[SerialPortID], Bauds[SerialPortBaudRate]);
       //     port = new Serial(this,ports[SerialPortID], 115200); // was 57600 115200
      port.buffer(3);
      port.clear();
    }
    updatedisplay();
    break;

  }
}
}

void decodeLetter()
{
  keyselection = 99;
  if((key > 64) && (key < 91)) 
  {
     keyselection = Letters.indexOf(key);
    
  } else if ((key > 96) && (key < 123))
  {
     keyselection = LettersLower.indexOf(key); 
  }
}

void stop()
{
  port.stop();
  myBus.close();
}