#include "udp-new.h"
#include "rtp.h"
#include "random.h"
#include <string.h>

int hdr_new::offset_;
 
static class UdpNewHeaderClass : public PacketHeaderClass {
public:
	UdpNewHeaderClass() : PacketHeaderClass("PacketHeader/UdpNew",sizeof(hdr_new)) {
		bind_offset(&hdr_new::offset_);
	}
} class_newhdr;


static class UdpNewAgentClass : public TclClass {
public:
	UdpNewAgentClass() : TclClass("Agent/UDP/UDPNew") {}
	TclObject* create(int, const char*const*) {
		return (new UdpNewAgent());
	}
} class_udpnew_agent;


UdpNewAgent::UdpNewAgent() : UdpAgent()
{
	new_support=false;
	info.seq=-1;
}

UdpNewAgent::UdpNewAgent(packet_t type) : UdpAgent(type)
{
	new_support=false;
	info.seq=-1;
}

void UdpNewAgent::recv(Packet* p, Handler*)
{
	hdr_ip* ih = hdr_ip::access(p);
	int bytes_to_deliver = hdr_cmn::access(p)->size();

	if(ih->prio==15)
	{
		if(app_) {
			hdr_new* nh = hdr_new::access(p);
			if(nh->seq == info.seq)
				info.rxbytes += hdr_cmn::access(p)->size();
			else {
				info.seq = nh->seq;
				info.totbytes = nh->nbytes;
				info.rxbytes = hdr_cmn::access(p)->size();
			}
			// if fully reassembled, pass the packet to application
			if(info.totbytes == info.rxbytes) {
				hdr_new nh_buf;
				memcpy(&nh_buf, nh, sizeof(hdr_new));
				app_->recv_msg(nh_buf.nbytes, (char*) &nh_buf);
			}
		}
		Packet::free(p);

		else { 
			if (app_) app_->recv(bytes_to_deliver);
			Packet::free(p);
		}
	}

}

void UdpNewAgent::sendmsg(int nbytes, const char* flag)
{
	Packet *p;
	int n;

	assert (size_ > 0);

	n=nbytes/size_;

	if(nbytes==-1)
	{
		printf("Error"); return;
	}

	while(n-- > 0)
	{
		p=allocpkt();
		hdr_cmn::access(p)->size() = size_;
		hdr_rtp* rh = hdr_rtp::access(p);
		rh->flags() = 0;
		rh->seqno() = ++seqno_;
		hdr_cmn::access(p)->timestamp() = (u_int32_t)(SAMPLERATE*local_time);

		//variant from udp

		hdr_new* nh= hdr_new::access(p);
		nh->ack=nh->seq=nh->nbytes=nh->scale=0;
		nh->time=0;

		if(new_support)
		{
			hdr_ip* ih = hdr_ip::access(p);
			ih->prio_ = 15;
			if(flags)
				memcpy(nh, flags, sizeof(hdr_new));
		}

		if (flags && (0 ==strcmp(flags, "NEW_BURST")))
			rh->flags() |= RTP_M;
		target_->recv(p);

	}

	n=nbytes%size_;

	if(n>0)
	{
		p=allocpkt();
		hdr_cmn::access(p)->size() = size_;
		hdr_rtp* rh = hdr_rtp::access(p);
		rh->flags() = 0;
		rh->seqno() = ++seqno_;
		hdr_cmn::access(p)->timestamp() = (u_int32_t)(SAMPLERATE*local_time);

		//variant from udp

		hdr_new* nh= hdr_new::access(p);
		nh->ack=nh->seq=nh->nbytes=nh->scale=0;
		nh->time=0;

		if(new_support)
		{
			hdr_ip* ih = hdr_ip::access(p);
			ih->prio_ = 15;
			if(flags)
				memcpy(nh, flags, sizeof(hdr_new));
		}

		if (flags && (0 ==strcmp(flags, "NEW_BURST")))
			rh->flags() |= RTP_M;
		target_->recv(p);
	}

	idle();

}