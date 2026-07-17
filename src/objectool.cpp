#include <iostream>
#include <fstream>		// for file input/output
#include <string>
#include <stdlib.h>     // atoi
#include <map>
using namespace std;	// this means i don't have to add std:: to everything 

string getOutput(string command) {
	FILE *fp;
	int status,len;
	char path[PATH_MAX];

	fp = popen(command.c_str(), "r");
	if (fp == NULL)
	    /* Handle error */;

	/*
	char* fgets(char* str,int count,FILE* stream);
	
    str: Pointer to an character array that stores the content of file.
    count: Maximum number of characters to write.
    stream: The file stream to read the characters.
	*/
	
	fgets(path, PATH_MAX, fp);
	status = pclose(fp);
	string out = path;
	out = out.substr(0,out.size()-1);
	return out;
}

int execute(string command) {system(command.c_str());}

int checkIfNumber(string str) {
	char *end;
	int val = strtol(str.c_str(), &end, 16);
	if (*end)
		return -1;
	else
		return val; 
}

string fixSlashes(string str) {
	string returnedString = str;
	for (int i=0;i<str.size();i++) {
		if (str.at(i) == *"\\")
			returnedString.replace(i,1,"/");
	}
	return returnedString;
}

string filename(string str) {
	string returnedString = str.substr(0,str.size()-4);
	for (int i=returnedString.size();i>=0;i--) {
		if (str.at(i) == *"/") {
			returnedString = returnedString.substr(i+1,returnedString.size());
			break;
		}
	}
	return returnedString;
}

int main(int argc,char *argv[]) {
	system("title Objectool");
	cout << "Objectool v1.00\n\n";
	string cd = fixSlashes(getOutput("echo(%cd%"));
	string work_path = cd+"/asm/work";
	string asm_path = cd+"/asm";
	string objects_path=cd+"/objects";
	string routines_path=cd+"/routines";
	string list_file = cd+"/list.txt";
	string rom_file;
	bool abortCompilation = false;
	
	if (getOutput("if exist \""+work_path+"\" (echo exists)") != "exists")
		execute("md \""+work_path+"\"");
	
	if (argv[1] == NULL) {
	inputRom:
		cout << "ROM file: ";
		char romfileTmp[PATH_MAX];
		fgets(romfileTmp,PATH_MAX,stdin);
		rom_file=romfileTmp;

		while (rom_file.at(0) == *" " || rom_file.at(0) == *"	")
			rom_file = rom_file.substr(1,rom_file.size()-1);
		
		if (rom_file.at(rom_file.size()-1) == *"\n")
			rom_file = rom_file.substr(0,rom_file.size()-1);
			
		if (rom_file == "") goto invalidInput;
		
		if (getOutput("if exist \""+cd+"/"+rom_file+"\" (echo exists)") == "exists") {
			cout<<"\n";
			rom_file = cd+"/"+rom_file;
		} else if (getOutput("if exist \""+rom_file+"\" (echo exists)") == "exists") {
			cout<<"\n";
		} else {
			cout<<"\nFile "+cd+"/"+rom_file+" not found.\n";
			system("pause");
		invalidInput:
			system("cls");
			cout << "Objectool v1.00\n\n";
			goto inputRom;
		}
	} else {
		rom_file = fixSlashes(argv[1]);
		if (getOutput("if exist \""+rom_file+"\" (echo exists)") != "exists" && getOutput("if exist \""+cd+"/"+rom_file+"\" (echo exists)") != "exists") {
			cout<<"\nFile "+cd+"/"+rom_file+" not found.\n";
			system("pause");
			return 1;
		}
	}
	
	if (argc > 2) {
		if (argv[2] != NULL) list_file=fixSlashes(argv[2]);
		if (argv[3] != NULL) objects_path=fixSlashes(argv[3]);
		if (argv[4] != NULL) routines_path=fixSlashes(argv[4]);
	}
	
	if (getOutput("if exist \""+list_file+"\" (echo exists)") != "exists") {
		cout << "list.txt is missing.\n";
		execute("pause>nul");
		return 1;
	}
	
	ifstream readList(list_file.c_str());	// must be char type
	string temp = work_path+"/generatedNamespaces.asm";
	execute("echo(>\""+temp+"\"");
	ofstream generatedNS(temp.c_str());

	map<string, int> NSID;

	string objectfiles[0xFFFF];
	string objectIDs[0xFFFF];
	string objectparams[0xFFFF];
	bool pointerExists[0x1FF];
	string line;
	bool listWarning = false,extendedWarning = false;
	int extendedRange = 0;
	int currentNamespace = 0;
	
	// use a while loop together with the getline() function to read the file line by line	
	for (int i=0;getline(readList, line);i++) {
		
		// set the extended range
		if (line.substr(0,10) == "EXTENDED:") {
			extendedRange=1;
			line = line.substr(9);
		}
	
		// initialize variables for this line
		objectIDs[i] = "undefined";
		
		int commentPos = 0;
		int spaces = 0;
		string uncommentedLine = line;
		
		// uncomment lines
		for (int j=0;j<line.size();j++) {
			// break if comment
			if (line.at(j) == *" "||line.at(j) == *"	") {
				spaces++;
			} else if (line.at(j) == *";") {
				break;
			} else {
				commentPos+=spaces+1;
				spaces=0;
			};
		}
		
		uncommentedLine.replace(0,line.size(),line,0,commentPos);
		
		int currentID = -1;
		
		// fill out IDs and files and parameters
		for (int j=0,word=0,ws=0,wl=0;j<uncommentedLine.size();j++) {	
			if ((uncommentedLine.at(j) == *" ") || (j==uncommentedLine.size()-1)) {
				
				if (j==uncommentedLine.size()-1) wl++;
				
				if (wl != 0) {
					// ID
					if (word==0) objectIDs[i] = uncommentedLine.substr(ws,wl);
					if (checkIfNumber(objectIDs[i]) == -1)
						objectIDs[i] = "invalid";
					else
						currentID = checkIfNumber(objectIDs[i])+(extendedRange*0x100);

					// parameter/file, second/third arguments
					if (word>=1 && currentID != -1) {
						if (word==1) {
							objectparams[currentID] = uncommentedLine.substr(ws,wl);
							if (checkIfNumber(objectparams[currentID]) == -1) {
								objectfiles[currentID] = fixSlashes(uncommentedLine.substr(ws,uncommentedLine.size()-1));
								objectparams[currentID] = "";
							}
						} else {
							if (word==2 && objectparams[currentID] != "") {
								objectfiles[currentID] = fixSlashes(uncommentedLine.substr(ws,uncommentedLine.size()-1));
							}
						}
					}
						
					word++;
				}
				
				ws=j;
				wl=0;
			} else {
				if (wl == 0) ws = j;
				wl++;
			}
		}
		
		string digitSpace="";
		if (i<9) digitSpace=" ";
		
		if (objectIDs[i] == "invalid") {
			if (!listWarning) {
				cout << list_file+":\n";
				listWarning=true;
				abortCompilation = true;
			}
			cout << "	line "+digitSpace<<i+1<<": Invlaid syntax.\n";
			
		} else if (currentID != -1) {
			// IDs
			if ((!extendedRange && (currentID > 0xFF || currentID < 0))
			||  ( extendedRange && (currentID > 0x1FF || currentID < 0x198))) {
				if (!listWarning) {
					cout << list_file+":\n";
					listWarning=true;
					abortCompilation = true;
				}
				if (!extendedRange)
					cout << "	line "+digitSpace<<i+1<<": Object IDs must be between 00 and FF.\n";
				else
					cout << "	line "+digitSpace<<i+1<<": Extended Object IDs must be between 98 and FF.\n";
			}
			
			// files and namespace output
			if (objectfiles[currentID] == "") {
				if (!listWarning) {
					cout << list_file+":\n";
					listWarning=true;
					abortCompilation = true;
				}
				cout << "	line "+digitSpace<<i+1<<": Invalid syntax.\n";
			} else {
				if (getOutput("if exist \""+objectfiles[currentID]+"\" (echo exists)") == "exists") {
					if (NSID[objectfiles[currentID]]==0) {
						NSID[objectfiles[currentID]]=currentNamespace+1;
						string digitSpace="";
						if (currentNamespace<0x10) digitSpace="0";
						generatedNS << "namespace OBJ"+digitSpace<<hex<<currentNamespace<<" : incsrc \""+objectfiles[currentID]+"\"\n";
						currentNamespace++;
					}
					
					pointerExists[currentID] = true;
					
				} else if (getOutput("if exist \""+objects_path+"/"+objectfiles[currentID]+"\" (echo exists)") == "exists") {
					if (NSID[objectfiles[currentID]]==0) {
						NSID[objectfiles[currentID]]=currentNamespace+1;
						string digitSpace="";
						if (currentNamespace<0x10) digitSpace="0";
						generatedNS << "namespace OBJ"+digitSpace<<hex<<currentNamespace<<" : incsrc \""+objects_path+"/"+objectfiles[currentID]+"\"\n";
						currentNamespace++;
					}
					
					pointerExists[currentID] = true;
	
				} else {
					if (!listWarning) {
						cout << list_file+":\n";
						listWarning=true;
						abortCompilation = true;
					}
					cout << "	line "+digitSpace<<i+1<<": File \""+objectfiles[currentID]+"\" doesn't exist.\n";
				}
			}
		}
	}

	readList.close();	
	generatedNS << "namespace off : OBJRT: RTS";
	generatedNS.close();
	
	// abort
	
	if (abortCompilation) {
		cout << "\nCompilation aborted.\n";
		system("pause>nul");
		return 1;
	}
	
	// generate pointers and parameters
	
	temp = work_path+"/generatedPointers.asm";
	execute("echo(>\""+temp+"\"");
	ofstream generatedPtrs(temp.c_str());
	temp = work_path+"/generatedParameters.asm";
	execute("echo(>\""+temp+"\"");
	ofstream generatedParams(temp.c_str());
	
	temp = work_path+"/generatedExPointers.asm";
	execute("echo(>\""+temp+"\"");
	ofstream generatedExPtrs(temp.c_str());
	temp = work_path+"/generatedExParameters.asm";
	execute("echo(>\""+temp+"\"");
	ofstream generatedExParams(temp.c_str());
	
	for (int i=0;i<=0x1FF;i++) {
		if (pointerExists[i] == true) {
			string digitSpace="";
			if (NSID[objectfiles[i]]-1<0x10) digitSpace="0";
			if (i >= 0x198)
				generatedExPtrs << "dw OBJ"+digitSpace<<hex<<NSID[objectfiles[i]]-1<<"_load\n";
			else
				generatedPtrs << "dw OBJ"+digitSpace<<hex<<NSID[objectfiles[i]]-1<<"_load\n";
		} else {
			if (i >= 0x198)
				generatedExPtrs << "dw OBJRT\n";
			else
				generatedPtrs << "dw OBJRT\n";
		}
		if (objectparams[i] == "") {
			if (i >= 0x198)
				generatedExParams << "dw $0000\n";
			else
				generatedParams << "dw $0000\n";
		} else {
			if (i >= 0x198)
				generatedExParams << "dw $"+objectparams[i]+"\n";
			else
				generatedParams << "dw $"+objectparams[i]+"\n";
		}
	}
		
	generatedParams.close();
	generatedPtrs.close();
	generatedExParams.close();
	generatedExPtrs.close();
	
	// routines folder
	
	temp = work_path+"/temp";		// file that contains all routine files
	execute("echo(>\""+temp+"\"");
	ifstream tempFile(temp.c_str());
	
	execute("dir \""+routines_path+"\" /B /S>\""+temp+"\"");
	
	temp = work_path+"/generatedRoutineMacros.asm";
	execute("echo(>\""+temp+"\"");
	ofstream generatedMacros(temp.c_str());
	temp = work_path+"/generatedRoutines.asm";
	execute("echo(>\""+temp+"\"");
	ofstream generatedRoutines(temp.c_str());

	map<string,int> RTID;

	for (int j,i=0;getline(tempFile, line);i++) {
		if (line.substr(line.size()-4,line.size()) == ".asm") {
			RTID[fixSlashes(line)] = j;
			
			generatedMacros << "!ObjectoolRoutineID_"<<RTID[fixSlashes(line)]<<" = 0\n";
			generatedMacros << "macro "+filename(fixSlashes(line))+"()\n";
			generatedMacros << "	!ObjectoolRoutineID_"<<RTID[fixSlashes(line)]<<" = 1\n";
			generatedMacros << "	JSL ObjectoolRoutine_"<<RTID[fixSlashes(line)]<<"_main\n";
			generatedMacros << "endmacro\n";
			
			generatedRoutines << "if !ObjectoolRoutineID_"<<RTID[fixSlashes(line)]<<"\n";
			generatedRoutines << "	namespace ObjectoolRoutine_"<<RTID[fixSlashes(line)]<<"\n";
			generatedRoutines << "	incsrc \""+fixSlashes(line)+"\"\n";
			generatedRoutines << "endif\n";
			j++;
		}
	}
	
	generatedRoutines << "namespace off";
	
	tempFile.close();
	generatedMacros.close();
	generatedRoutines.close();
	
	// execute asar
	
	int errorlevel = execute("cd \""+asm_path+"\" & asar.exe \""+asm_path+"/main.asm\" \""+fixSlashes(rom_file)+"\"");
	
	if (errorlevel == 0) {
		cout << "Object code inserted successfully.";
		execute("pause>nul");
		return 0;
	} else {
		execute("pause>nul");
		return 1;
	}
}


