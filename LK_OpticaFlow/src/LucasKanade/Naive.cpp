 #include <iostream>
 #include <fstream>
#include <bits/stdc++.h> 
#include <sstream> 
#include <bitset>
#include <vector>

using namespace std;

#define P 1 
#define X 10 
#define Y 9 
#define T 32 

const int width = 240, height = 180;

std::vector< int > get_bits( unsigned long x ) {
    std::string chars( std::bitset< sizeof(long) * CHAR_BIT >(x)
        .to_string( char(0), char(1) ) );
    return std::vector< int >( chars.begin(), chars.end() );
}

vector<int> convert(int x) {
  vector<int> ret;
  while(x) {
    if (x&1)
      ret.push_back(1);
    else
      ret.push_back(0);
    x>>=1;  
  }
  reverse(ret.begin(),ret.end());
  return ret;
}

int main(){


/////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////// Reading the Dataset ////////////////////////
	/////////////////////////////////////////////////////////////////////////////////////
ifstream ip("rotDisc.csv");
if(!ip.is_open()) std::cout << "ERROR: File Open" << "\n";

int *iipolarities = (int*) malloc( 374295 * sizeof(int) );

// vector<bitset<P>> bpolarity;
// vector<bitset<X>> bxaddr;
// vector<bitset<Y>> byaddr;
// vector<bitset<T>> btimestamp;

string polarity;
string xaddr;
string yaddr;
string timestamp;

vector<bool> vpolarity;
vector<float> vtimestamp;
vector<unsigned short int> vxaddr;
vector<unsigned short int> vyaddr;

while(ip.good()){
	getline(ip,timestamp,',');
	getline(ip,xaddr,',');
	getline(ip,yaddr,',');
	getline(ip,polarity,'\n');
	stringstream geek1(polarity);
	stringstream geek2(timestamp);
	stringstream geek3(xaddr);
	stringstream geek4(yaddr);

	//	int ipolarity=0;
	bool bpolarity =0; // define one bit for polarity value
	float ftimestamp =0; // define 32 bits for timestamp
	unsigned short int uixaddr =0; // define 16 bits for x addr
	unsigned short int uiyaddr =0; // define 16 bits for y addr
	geek1 >> bpolarity;
	geek2 >> ftimestamp;
	geek3 >> uixaddr;
	geek4 >> uiyaddr;
	vpolarity.push_back(bpolarity);
	vtimestamp.push_back(ftimestamp);
	vxaddr.push_back(uixaddr);
	vyaddr.push_back(uiyaddr);
}
////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////End of reading //////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////

	for (int i=0;i<= 5;i++){
		std::cout << vtimestamp[i] << "\n";
	}
int nframes = 100;
int Nevents = 5000;
int Refractory_period = 500;
long int timestampcount =0;
long int temp =0;



// /////
// ofstream img("picture.ppm");
// img << "p3" << endl;
// img << width << " " << height << endl;
// img << "255" << endl;
// for (int y =0;y<height;y++){
// 	for(int x=0;x<width;x++){
// 		int r=x%255;
// 		int g=y%255;
// 		int b=y*x%255;
// 		img << r << " " << g << " " << b << endl;
// 	}
// }
////
return 0;
}