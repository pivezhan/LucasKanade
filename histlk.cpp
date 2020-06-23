#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <vector>
#include <chrono>
#include <fstream>
#include <bits/stdc++.h>

void write_csv(std::string filename, std::vector<std::string> vals){
    // Make a CSV file with one column of integer values
    // filename - the name of the file
    // colname - the name of the one and only column
    // vals - an integer vector of values

    // Create an output filestream object
    std::ofstream myFile(filename);

    // Send the column name to the stream
    // myFile << colname << "\n";

    // Send data to the stream
    for(int i = 0; i < vals.size(); ++i)
    {
        myFile << vals.at(i) << "\n";
    }

    // Close the file
    myFile.close();
}

void read_csv(int row, char *filename, int **data){
    FILE *file;
    file = fopen(filename, "r");

    int i = 0;
    char line[40];
    while (fgets(line, 40, file) && (i < row))
    {
// The csv file has four different columns for ts, x, y, type
        data[i][0] = int(atof(strtok(line, ",")));
        data[i][1] = int(atof(strtok(NULL, ",")));
        data[i][2] = int(atof(strtok(NULL, ",")));
        data[i][3] = int(atof(strtok(NULL, ",")));
        i++;
    }
}

int pop_front(std::vector<int> &v)
{
    if (v.size() > 0) {
        v.front() = std::move(v.back());
        v.pop_back();
    }
}

int main(int argc, char const *argv[])
{
    int NumberOfEvents, EventsPerPackets, RefractoryPeriod;
    int searchDistance=3;
    int d = 0; // additional space for the borders of the chip
    int maxthreshold = 100000;

// // initializing the arguments
    if (argc==3){
        RefractoryPeriod = 1;  // the refractory period
        NumberOfEvents = atoi(argv[1]); // total events
        EventsPerPackets = atoi(argv[2]); // total events per packet
    }else if(argc==2){
        EventsPerPackets = 10;
        RefractoryPeriod = 1;
        NumberOfEvents = atoi(argv[1]); // total rows
    }else if (argc==1){
        NumberOfEvents = 10;
        EventsPerPackets = 10;
        RefractoryPeriod = 1;
        printf("You didn't enter arguments\n");
    }else if (argc==4){
        NumberOfEvents = atoi(argv[1]); // total events
        EventsPerPackets = atoi(argv[2]); // total events per packet
        RefractoryPeriod = atoi(argv[3]); // refractory period
    }
    else{
        return 0;
    }
    // printf("the number of arguments= %d\n", argc);

    int Xcols= 240; //dvs number of columns
    int Yrows = 180; //dvs number of rows
    // int histsize = 2; //the number of histogram elements
    char fname[256];
    strcpy(fname, "IMU_APS_rotDisk.csv");
    int **data;
    data = (int **)malloc(NumberOfEvents * sizeof(int *));
    for (int i = 0; i < NumberOfEvents; ++i){
        data[i] = (int *)malloc(4 * sizeof(int));
    }
    read_csv(NumberOfEvents, fname, data);
    // for (int i=0; i<NumberOfEvents; i++){
    // printf("event %d is: ts= %d, y= %d, x= %d, type= %d\n", i, data[i][0], data[i][1], data[i][2], data[i][3]);
    // }
    std::vector<std::vector<std::vector<std::vector<int> > > > timestamp1 = std::vector<std::vector<std::vector<std::vector<int> > > > (Xcols, std::vector<std::vector<std::vector<int> > >(Yrows, std::vector<std::vector<int> >(2,std::vector<int>(0)))); // -1 polarity bit
    std::vector<std::vector<std::vector<std::vector<int> > > > timestamp2 = std::vector<std::vector<std::vector<std::vector<int> > > > (Xcols, std::vector<std::vector<std::vector<int> > >(Yrows, std::vector<std::vector<int> >(2,std::vector<int>(0)))); // -1 polarity bit
	// int totalevents = ((NumberOfEvents - EventsPerPackets)/RefractoryPeriod)*EventsPerPackets;

/// writing to the log file ////
	std::vector<std::string> outstream;
	std::string tempstring;

// X address: (239 - data[p+e][2])
// Y address: data[p+e][1]
// ts : data[p+e][0]
// P : data[p+e][3]

/// Histogram Creation Section ////
  auto TDstart = std::chrono::high_resolution_clock::now();
  long int count = 0;
    for (int p = 0; p <= NumberOfEvents - EventsPerPackets; p += RefractoryPeriod){ //this is for frame by frame process
        for(int e = 0; e < EventsPerPackets; e++){//this is for processing events within packets
                timestamp1[(239 - data[p+e][2])][data[p+e][1]][data[p+e][3]].push_back(data[p+e][0]);
                timestamp2[(239 - data[p+e][2])][data[p+e][1]][data[p+e][3]].push_back(data[p+e][0]);
                for (int j = -searchDistance - d; j<= searchDistance + d; j++){
                    for (int i= -searchDistance - d; i<= searchDistance + d; i++){
                        if ((data[p+e][1] + j) >= 0 and (data[p+e][1] + j) < 180 and ((239 - data[p+e][2]) + i) >= 0 and ((239 - data[p+e][2]) + i) < 240){
							// std::cout << (239 - data[p+e][2]) << ", " << data[p+e][1] << ", " << data[p+e][3] << ", " << data[p+e][0] << "," << timestamp1[(239 - data[p+e][2])][data[p+e][1]][data[p+e][3]].size() << ", " << timestamp1[(239 - data[p+e][2])][data[p+e][1]][data[p+e][3]].empty() << "\n";
							// std::cout << data[p+e][0]  << ", " << pop_front(timestamp1[(239 - data[p+e][2])+i][data[p+e][1]+j][data[p+e][3]]) + maxthreshold << " before" << "\n";
                            while((pop_front(timestamp1[(239 - data[p+e][2])+i][data[p+e][1]+j][data[p+e][3]])!=F) && (data[p+e][0] > (pop_front(timestamp1[(239 - data[p+e][2])+i][data[p+e][1]+j][data[p+e][3]])+maxthreshold))){
							// std::cout << (239 - data[p+e][2]) << ", " << data[p+e][1] << ", " << data[p+e][3] << ", " << data[p+e][0] << "," << timestamp1[(239 - data[p+e][2])][data[p+e][1]][data[p+e][3]].size() << ", " << timestamp1[(239 - data[p+e][2])][data[p+e][1]][data[p+e][3]].empty() << "\n";
							              std::cout << data[p+e][0]  << ", " << pop_front(timestamp1[(239 - data[p+e][2])+i][data[p+e][1]+j][data[p+e][3]]) << " after" <<"\n";
                                // timestamp1[(239 - data[p+e][2])+i][data[p+e][1]+j][data[p+e][3]].erase(timestamp1[(239 - data[p+e][2])+i][data[p+e][1]+j][data[p+e][3]].begin());
                            }
                //             while((pop_front(timestamp2[(239 - data[p+e][2])+i][data[p+e][1]+j][data[p+e][3]])!=0) && (data[p+e][0] > pop_front(timestamp2[(239 - data[p+e][2])+i][data[p+e][1]+j][data[p+e][3]])+2*maxthreshold)){
								// // std::cout << (data[p+e][0] > pop_front(timestamp1[(239 - data[p+e][2])+i][data[p+e][1]+j][data[p+e][3]])+maxthreshold) << "ddd";
                //                 timestamp2[(239 - data[p+e][2])+i][data[p+e][1]+j][data[p+e][3]].erase(timestamp2[(239 - data[p+e][2])+i][data[p+e][1]+j][data[p+e][3]].begin());
                //             }
							tempstring = std::to_string((239 - data[p+e][2])+i) + ", " + std::to_string(data[p+e][1] + j) + ", " + std::to_string(data[p+e][3]) + ", " + std::to_string(data[p+e][0]) + ", " + std::to_string(timestamp1[(239 - data[p+e][2])+i][data[p+e][1]+j][data[p+e][3]].size()); //  + std::to_string(timestamp1[data[p+e][2]+i][data[p+e][1]+j][data[p+e][3]].size());
							outstream.push_back(tempstring);
                        }
                    }
                }

				count++;
        }
    }
    auto TDstop = std::chrono::high_resolution_clock::now();
    double TD = std::chrono::duration_cast <std::chrono::nanoseconds> (TDstop - TDstart).count();
    double RT = double(TD/count)/(1000000000);
	std::cout << "Per event RT: " << RT << ", count: " << count  << ", EventsPerPackets: "  << EventsPerPackets  << ", NumberOfEvents: "  << NumberOfEvents << ", RefractoryPeriod: " << RefractoryPeriod << "\n";
	write_csv("rotDisk0cpp.csv", outstream);
    return 0;
}
