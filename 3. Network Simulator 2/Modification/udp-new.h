
#include "ip.h"
#include "udp.h"

struct hdr_new {
	bool ack;
	int nbytes;
	int seq;
	double time;
	int scale; //(0-9)

	static int offset_;
    inline static int& offset() { return offset_; }
    inline static hdr_new* access(const Packet* p) {
            return (hdr_new*) p->access(offset_);
    }
};

struct packet_info {
	int seq;
	int rxbytes;
	int totbytes;
}

class UdpNewAgent : public UdpAgent 
{
public: 
	UdpNewAgent();
	UdpNewAgent(packet_t);
	virtual int supportNew() { return 1; }
	virtual void enableNew() { new_support = true; }
	virtual void sendmsg(int nbytes, const char *flags = 0);
	void recv(Packet*, Handler*);
protected:
	bool new_support;
private:
	packet_info info;

}
