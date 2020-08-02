#include<bits/stdc++.h>
#include<windows.h>

#define NMAXBIT 5000

#define hi cout<<"Hi"<<endl;
#define GREEN 10
#define CYAN 11
#define RED 12
#define GREY 7

using namespace std;

vector <vector<int> > mat;
vector <vector<int> > rmat;
vector <vector<int> > rcmat;
vector<int> serial_bits;
bool isError[NMAXBIT];
int num_check_bits=0;
int num_bits_in_row=0;
int k=0;


vector<int> getBitPattern(char ch)
{
    vector<int> ret(8,0);
    int idx=7;
    while(ch)
    {
        ret[idx--]=ch%2;
        ch/=2;
    }
    return ret;
}

void createDataBlock(int row,int col,string data)
{
    int idx=0;
    for(int i=0; i<row; i++)
    {
        vector<int> rowVec;
        for(int j=0; j<col; j++)
        {
            vector<int> bits = getBitPattern(data[idx]);
            rowVec.insert(rowVec.end(),bits.begin(),bits.end());
            idx++;
        }
        mat.push_back(rowVec);
    }
}

void showDataBlock(int row,int m,bool isColor)
{
    for(int i=0; i<row; i++)
    {
        int pow=1;
        for(int j=0; j<m*8+num_check_bits; j++)
        {
            if(j+1==pow and isColor)
            {
                SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), GREEN);
                pow=pow*2;
            }
            else if(isColor) SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), GREY);
            cout<<mat[i][j];

        }
        cout<<endl;
    }
    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), GREY);
}

int getCheckBit(int row,int pos)
{
    int factor=1;
    int count=0;
    for(int i=1;; i+=2)
    {
        for(int j=i*pos; j<i*pos+pos; j++)
        {
            if(j>num_bits_in_row) goto finish;
            count= count + (mat[row][j-1] ==1 ? 1 : 0);

        }
    }

finish:
    //if(row==0 and pos==1) cout<<count<<endl;

    return count%2;
}


void addCheckBits(int row, int m)
{
    int num_bits=m*8;
    num_check_bits=log2(num_bits)+1;
    num_bits_in_row= (m*8+num_check_bits);

    for(int i=0; i<row; i++)
    {
        int pos=1;
        for(int j=0; j<num_check_bits; j++)
        {
            mat[i].insert(mat[i].begin()+(pos-1),0);
            pos=pos*2;
        }
    }

    for(int i=0; i<row; i++)
    {
        int pos=1;
        for(int j=0; j<num_check_bits; j++)
        {
            //cout<<pos<<" ";
            mat[i][pos-1]= getCheckBit(i,pos);
            pos=pos*2;
        }
        // cout<<endl;
    }
}

void serialize(int row)
{
    serial_bits.clear();
    for(int j=0; j<num_bits_in_row; j++)
    {
        for(int i=0; i<row; i++)
        {
            serial_bits.push_back(mat[i][j]);
        }
    }

    for(int i=0; i<serial_bits.size(); i++)
    {
        cout<<serial_bits[i];
    }
    cout<<endl;

}

void printV(vector<int> vec)
{
    for(int i=0; i<vec.size(); i++) cout<<vec[i];
    cout<<endl;
}

vector<int> Xor(vector<int> a, vector<int>b)
{
    vector<int> ret;

    for(int i=1; i<a.size(); i++)
    {
        ret.push_back( (a[i]==b[i] ? 0 : 1) );
    }

    return ret;
}
vector<int> division(vector<int> dividend, vector<int> divisor)
{
    int len= dividend.size();
    vector<int> ret;
    int idx=0;
    while(dividend[idx]==0)
        idx++;
    vector<int> div_(dividend.begin()+idx, dividend.begin()+idx+k);
    idx=idx+k-1;
    //printV(div_);
    vector<int> dvs_;
    while(idx<len)
    {
        vector<int> temp(k,0);
        if(div_[0]==0) dvs_=temp;
        else dvs_=divisor;
        div_ = Xor(div_,dvs_);
        ++idx;
        if(idx==len) break;
        div_.push_back(dividend[idx]);
        //printV(div_);
    }
    return div_;
}

void showSentFrame(vector<int> frame)
{
    for(int i=0; i<frame.size(); i++)
    {
        if(i>=frame.size()-k+1)
            SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), CYAN);
        cout<<frame[i];
    }
    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), GREY);
}

vector<int> stringToVector(string str)
{
    vector<int> ret;
    for(int i=0; i<str.size(); i++)
        ret.push_back(str[i]-'0');
    return ret;
}

double jimsrand(void)
{
    double mmm = RAND_MAX;
    float x;                 /* individual students may need to change mmm */
    x = rand() / mmm;        /* x should be uniform in [0,1] */
    return (x);
}


vector<int> receive_with_error(vector<int> sentFrame,double prob)
{
    vector<int> ret= sentFrame;
    memset(isError,0,sizeof(isError));
    for(int i=0; i<sentFrame.size(); i++)
    {
        if( jimsrand() < prob )
        {
            isError[i]=true;
            ret[i]=1-ret[i];
            SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), RED);
        }
        else
            SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), GREY);
        cout<<ret[i];
    }
    cout<<endl;
    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), GREY);
    return ret;

}

bool checkError(vector<int> rframe,vector<int> pgen)
{
    vector<int> rem= division(rframe,pgen);
    bool ret=false;
    for(int i=0; i<rem.size(); i++)
    {
        if(rem[i])
        {
            ret=true;
            break;
        }
    }

    if(ret) cout<<"Error detected"<<endl;
    else cout<<"No Error detected"<<endl;

    return ret;
}

void deserialize(vector<int> rframe,int row)
{
    int idx=k-1;
    vector<int> ret= rframe;

    while(idx--)
        ret.pop_back();

    idx=0;

    vector<int> vec(num_bits_in_row,0);
    for(int i=0; i<row; i++)
        rmat.push_back(vec);

    for(int j=0; j<num_bits_in_row; j++)
    {
        for(int i=0; i<row; i++)
        {
            rmat[i][j]= ret[idx];
            idx++;
        }
    }

    for(int i=0;i<row;i++)
    {
        for(int j=0;j<num_bits_in_row;j++)
        {
            int id= row*j + i;
            if(isError[id]) SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), RED);
            else SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), GREY);
            cout<<rmat[i][j];
        }
        cout<<endl;
    }
    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), GREY);
}

void removeCheckBits(int row)
{
    for(int i=0;i<row;i++)
    {
        int cnt=0;
        for(int pos=1;pos<num_bits_in_row;pos=pos*2)
        {
            rmat[i].erase(rmat[i].begin()+pos-cnt-1);
            cnt++;
        }
    }

    for(int i=0;i<rmat.size();i++)
    {
        for(int j=0;j<rmat[i].size();j++)
            cout<<rmat[i][j];
        cout<<endl;
    }
}

int getCheckBitAgain(int row,int pos)
{
    int count=0;
    for(int i=1;; i+=2)
    {
        for(int j=i*pos; j<i*pos+pos; j++)
        {
            if(j>rcmat[row].size()) goto finish;
            count= count + (rcmat[row][j-1] ==1 ? 1 : 0);
        }
    }

finish:
    //if(row==0 and pos==1) cout<<count<<endl;

    return count%2;
}
void print2Dvector(vector< vector<int> > vec)
{
    cout<<"\n----- Printing matrix---\n\n";
    for(int i=0;i<vec.size();i++)
    {
        for(int j=0;j<vec[i].size();j++)
        {
            cout<<vec[i][j];
        }
        cout<<endl;
    }
    cout<<endl;
}

void errorCorrection(int row)
{
    for(int i=0;i<row;i++)
    {
        int count=0;
        for(int pos=1;pos<rcmat[i].size();pos=pos*2)
        {
            int cbit= getCheckBitAgain(i,pos);
            if(cbit) count+= pos;
        }
        if(count)
        {
            cout<<i<<"th row : Error in bit no: "<<count<<endl;
            if(count<=rcmat[i].size()) rcmat[i][count-1]= 1- rcmat[i][count-1];
        }
    }
    cout<<"\nAfter correcting the matrix--\n";
    print2Dvector(rcmat);
}

string bitToString(vector<int> bits)
{
    int prod=1;
    int sum=0;
    for(int i=bits.size()-1;i>=0;i--)
    {
        sum += bits[i]*prod;
        prod*=2;
    }
    string ret="A";
    ret[0]= sum;
    //cout<<"****   "<<sum<<endl;
    return ret;
}


string printOutput(int row)
{
    string output="";

    //print2Dvector(rcmat);

    for(int i=0;i<rcmat.size();i++)
    {
        for(int j=0;j<rcmat[i].size();j+=8)
        {
            //if(j>=num_bits_in_row-num_check_bits) break;
            vector<int> temp;
            for(int k=j;k<j+8;k++)
                temp.push_back(rcmat[i][k]);

            //printV(temp);
            output += bitToString(temp);
        }
    }
    return output;
}

void copyVec()
{
    //cout<<"Copying-----\n";
    for(int i=0;i<rmat.size();i++)
    {
        vector<int> temp;
        for(int j=0;j<rmat[i].size();j++)
        {
            temp.push_back(rmat[i][j]);
            //cout<<rmat[i][j];
        }
        //cout<<endl;
        rcmat.push_back(temp);
    }
}

void removeCheckBitsAgain(int row)
{
    for(int i=0;i<row;i++)
    {
        int cnt=0;
        for(int pos=1;pos<num_bits_in_row;pos=pos*2)
        {
            rcmat[i].erase(rcmat[i].begin()+pos-cnt-1);
            cnt++;
        }
    }

    for(int i=0;i<rcmat.size();i++)
    {
        for(int j=0;j<rcmat[i].size();j++)
            cout<<rcmat[i][j];
        cout<<endl;
    }
}

int main()
{

    //freopen("input.txt","r",stdin);

    srand ( unsigned (time(0)));

    int m;
    double p;
    string data,polynomial;

    cout<<"enter data string: ";
    getline(cin,data);

    cout<<"enter number of bytes in a row : ";
    cin>>m;

    cout<<"enter error probability : ";
    cin>>p;

    cout<<"enter generator polynomial : ";
    cin>>polynomial;

    int rem=data.size()%m;
    int div=data.size()/m;
    if(rem) rem= (div+1)*m- data.size();
    string app_char="~";

    for(int i=0; i<rem; i++)
        data += app_char;

    cout<<"Data string after appending: "<<data<<endl;

    int row=data.size()/m;
    createDataBlock(row,m,data);
    showDataBlock(row,m,false);

    cout<<"\nData block after adding check bits\n";
    addCheckBits(row,m);
    showDataBlock(row,m,true);

    cout<<"\nAfter serializing \n";
    serialize(row);

    vector<int> sentFrame(serial_bits.begin(),serial_bits.end());
    k=polynomial.size();
    vector<int> vec(k-1,0);
    serial_bits.insert(serial_bits.end(),vec.begin(),vec.end());

    vector<int> gen=stringToVector(polynomial);
    vector<int> checksum= division(serial_bits,gen);
    sentFrame.insert(sentFrame.end(),checksum.begin(),checksum.end());

    cout<<"\nAfter appending CRC checksum (sent frame) :\n";

    showSentFrame(sentFrame);

    cout<<"\nRecieved Frame :\n";
    vector<int> receivedFrame = receive_with_error(sentFrame,p);

    cout<<"\nResult after checksum matching:\n";
    checkError(receivedFrame,gen);

    cout<<"\ndata block after removing CRC checksum:\n";
    deserialize(receivedFrame,row);

    //rcmat.assign(rmat.begin(),rmat.end());
    copyVec();


    cout<<"\ndata block after removing check bits\n";
    removeCheckBits(row);

    cout<<"\nCorrection begins\n"<<endl;
    errorCorrection(row);
    cout<<"\nAfter removing check bits\n";
    removeCheckBitsAgain(row);

    cout<<"\nOutput frame---\n";
    cout<<printOutput(row)<<endl;

    return 0;
}
