#include <cstdio>
#include <cstring>
#include <cstdlib>

#include<bits/stdc++.h>

#include <string>
#include <iostream>
#include <fstream>
#include <vector>
#include <map>

#include <arpa/inet.h>
#include <sys/socket.h>
#include <unistd.h>

using namespace std;

#define printAll(v) for(int i=0;i<v.size();i++) cout<<v[i]<<endl;
#define PORT 4747
#define dbg printf("Here\n")

string myIP="";
string routingInfo="";

int sockfd;
int bind_flag;

int stringToInt(string str)
{
	stringstream ss(str);
	int ret;
	ss >> ret;
	return ret;
}

string intToString(int a)
{
	stringstream ss;
	ss << a;
	return ss.str();
}


class Route
{
public:
	string dest;
	string nextHop;
	int cost;

	Route(string d,string nh,int c){ dest=d; nextHop=nh; cost=c; }

};

//vector< pair<string,int> >adjList;
vector<Route> routingTable;
map<string,int> adjList;
set<string> routers;

void printAdjList()
{
	printf("The adjacency list\n");
	map<string, int>::iterator it;
	for(it=adjList.begin();it!=adjList.end();++it)
		cout<<it->first<<"\t"<<it->second<<endl;
}


void getNeighbours(char* ownIP, char *fileName)
{
	string ip(ownIP);
	myIP=ip;
	ifstream file(fileName);
	if (file.is_open()) {
	    string line;
	    string delim=" ";
	    while (getline(file, line)) {
		
		//printf("%s\n", line.c_str());

			size_t start=0;
			size_t end=line.find(delim);

			vector<string> vec;
		   
		    while (end != string::npos)
		    {
		    	vec.push_back(line.substr(start, end - start));
		        start = end + delim.length();
		        end = line.find(delim, start);
		    }
		    vec.push_back(line.substr(start, end));

		    stringstream ss(vec[2]);
		    int cost;
		    ss >> cost;

		    routers.insert(vec[0]);
		    routers.insert(vec[1]);

		    if(vec[0]==ip) adjList.insert(make_pair(vec[1],cost));
		    else if(vec[1]==ip) adjList.insert(make_pair(vec[0],cost));

	    }
	    file.close();
	}
}

string getRoutingTable()
{
	string ret="";
	for(int i=0;i<routingTable.size();i++)
	{
		ret+=routingTable[i].dest+" ";
		ret+=routingTable[i].nextHop+" ";

		stringstream ss;
		ss << routingTable[i].cost;
		ret+= ss.str()+"\n";	
	}

	routingInfo=ret;
	return ret;
}

void initiateRoutingTable(char* ownIP)
{
	string ip(ownIP);
	set<string>::iterator it;
	map<string,int>::iterator mpit;

	routingTable.clear();
	//printf("Destination  \tNext Hop   \tCost\n");
	for(it=routers.begin();it!=routers.end();++it)
	{
		string cur=*it;
		if(cur==ip) continue;
		//cout<<cur<<"\t";
		string hop="";
		int c= INT_MAX;
		mpit=adjList.find(cur);
		if(mpit!=adjList.end())
		{
			hop=mpit->first;
			c=mpit->second;
		}
		//cout<<hop<<"\t"<<c<<endl;

		Route r(cur,hop,c);
		routingTable.push_back(r);
	}
	getRoutingTable();
}

string parse(char * message)
{
	if(strlen(message)<=0) return "";
	string str(message);
	int idx=0;
	int len=4;
	string command=str.substr(idx,len);
	idx+= len;

	//cout<<str.size()<<endl;
	//cout<<strlen(message)<<endl;

	string ip="";

	for(int i=0;i<4;i++)
	{
		unsigned char ch= str[idx+i];
		int segment= ch; 
		stringstream ss;
		ss<<segment;

		ip+= ss.str();

		if(i!=3) ip+= ".";

		cout<<segment<<endl;
	}

	return ip;

}

int getCostFromCommand(char* message)
{

	string str(message);

	string ip1="";

	int idx=4;

	for(int i=0;i<4;i++)
	{
		unsigned char ch= str[idx+i];
		int segment= ch; 
		stringstream ss;
		ss<<segment;

		ip1+= ss.str();

		if(i!=3) ip1+= ".";

		//cout<<segment<<endl;
	}

	string ip2="";
	idx=8;

	for(int i=0;i<4;i++)
	{
		unsigned char ch= str[idx+i];
		int segment= ch; 
		stringstream ss;
		ss<<segment;

		ip2+= ss.str();

		if(i!=3) ip2+= ".";

		//cout<<segment<<endl;
	}

	unsigned char lo= str[12];
	unsigned char hi= str[13];
	int cost= (hi<<8) | lo;

	cout<<ip1<<" "<<ip2<<" "<<cost<<endl;
	cout<<myIP<<endl;

	if(ip1==myIP)
	{
		dbg;
		map<string,int>::iterator mpit;
		mpit=adjList.find(ip2);
		if(mpit!=adjList.end())
		{
			mpit->second=cost;
		}
		else
		{
			adjList.insert(make_pair(ip2,cost));
		}
	}
	else if(ip2==myIP)
	{
		dbg;
		map<string,int>::iterator mpit;
		mpit=adjList.find(ip1);
		if(mpit!=adjList.end())
		{
			mpit->second=cost;
		}
		else
		{
			adjList.insert(make_pair(ip1,cost));
		}
	}

	cout<<cost<<endl;
	return cost;
}

void showRoutingTable()
{
	printf("Destination  \tNext Hop   \tCost\n");	
	for(int i=0;i<routingTable.size();i++)
	{
		cout<<routingTable[i].dest<<"\t";
		cout<<routingTable[i].nextHop<<"\t";
		cout<<routingTable[i].cost<<"\n";
	}
}



void sendMessage(string ip,string message)
{
	struct sockaddr_in neigh_address;
	neigh_address.sin_family = AF_INET;
	neigh_address.sin_port = htons(4747);
	neigh_address.sin_addr.s_addr = inet_addr(ip.c_str());

	int len=message.size()+1;
	char buf[len];
	strcpy(buf,message.c_str());

	sendto(sockfd, buf, len, 0, (struct sockaddr*) &neigh_address, sizeof(sockaddr_in));

}

void updateNeighbours()
{
	cout<<"Updating...\n";
	map<string,int>::iterator it;
	string info="update\n"+routingInfo;
	for(it=adjList.begin();it!=adjList.end();++it)
	{
		string temp=it->first;
		sendMessage(temp, info);
	}
}

void utilCalc(Route rt,string nIP)
{
	for(int i=0;i<routingTable.size();i++)
	{
		if(rt.dest == routingTable[i].dest and rt.cost < routingTable[i].cost)
		{
			routingTable[i].cost=rt.cost;
			routingTable[i].nextHop= nIP;
			break;
		}
	}
}

void recalculateRoutingTable(char *info,string neighIP)
{
	string fullInfo(info);

	istringstream f(fullInfo);

	string line;

	while(getline(f,line))
	{
		istringstream fs(line);
		string token;
		vector<string> tokens;
		while(getline(fs,token,' '))
		{
			tokens.push_back(token);
		}

		string dest=tokens[0];
		string hop=tokens[1];
		int cost= stringToInt(tokens[2]);

		Route r(dest,hop,cost);
		utilCalc(r,neighIP);

	}

}



int main(int argc, char *argv[]){

	
	char buffer[1024];
	struct sockaddr_in server_address;
	struct sockaddr_in client_address;


	int bytes_received;

	string driverIP= "192.168.1.100";
	

	if(argc < 3){
		printf("%s <ip address>\n", argv[0]);
		exit(1);
	}

	getNeighbours(argv[1],argv[2]);
	printAdjList();
	initiateRoutingTable(argv[1]);
	showRoutingTable();

	
	/*server_address.sin_family = AF_INET;
	server_address.sin_port = htons(PORT);
	inet_pton(AF_INET, driverIP.c_str() , &server_address.sin_addr); */
	//server_address.sin_addr.s_addr = inet_addr("192.168.1.100");

	

	client_address.sin_family = AF_INET;
	client_address.sin_port = htons(PORT);
	inet_pton(AF_INET, argv[1], &client_address.sin_addr);
	//client_address.sin_addr.s_addr = inet_addr(argv[1]);
	
	sockfd = socket(AF_INET, SOCK_DGRAM, 0);

	bind_flag = bind(sockfd, (struct sockaddr*) &client_address, sizeof(sockaddr_in));

	if(!bind_flag) cout<<"Connection oka..."<<endl;
	else cout<<"Connection not oka..."<<endl;

	struct sockaddr_in router_address;
	socklen_t addrlen;
	
	printf("Check...\n");


	while(true){

		//bytes_received = recvfrom(sockfd, buffer, 1024, 0, (struct sockaddr*) &server_address, &addrlen);
		char buffer[1024];
		memset(buffer,0,sizeof(buffer));
		bytes_received = recvfrom(sockfd, buffer, 1024, 0, (struct sockaddr*) &router_address, &addrlen);

		if(bytes_received!=-1)
		{
			//cout << "Hello from : \n" ;
			//buffer[bytes_received]=0;
			string rec(buffer);
			//printf("%s\n",buffer);
			//cout<<parse(buffer)<<endl;
			if(rec.substr(0,4)=="show") showRoutingTable();
			else if(rec.substr(0,4)=="cost")
			{
				int newCost = getCostFromCommand(buffer);
				initiateRoutingTable(argv[1]);
				showRoutingTable();
			}
			else if(rec.substr(0,3)=="clk")
			{
				updateNeighbours();
			}
			else if(rec.substr(0,6)=="update")
			{
				cout<<"Got the update\n";

			}
			//fflush(stdout);
		}

		//fgets(buffer,1024,stdin);
		//if(!strcmp(buffer, "shutdown")) break;
		//sendto(sockfd, buffer, 1024, 0, (struct sockaddr*) &server_address, sizeof(sockaddr_in));
		//printf("%s\n",buffer);
	}

	close(sockfd);

	return 0;

}
