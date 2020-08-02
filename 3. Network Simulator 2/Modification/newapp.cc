#include "timer-handler.h"
#include "packet.h"
#include "app.h"
#include "udp-new.h"

class SendTimer;
class AckTimer;

struct pkt_acc
{
	int last_seq;
	int last_scale;
	int recv_pkts;
	int lost_pkts;
	double rtt;
}

class newApp : public Application{

public:
	newApp();
	void send_mm_pkt();  
	void send_ack_pkt();
 protected:
	int command(int argc, const char*const* argv);
	void start();       
	void stop();      
 private:
	void init();
	inline double next_snd_time();                          // (Sender)
	virtual void recv_msg(int nbytes, const char *msg = 0); // (Sender/Receiver)
	void set_scale(const hdr_mm *mh_buf);                   // (Sender)
	void adjust_scale(void);                                // (Receiver)
	void account_recv_pkt(const hdr_mm *mh_buf);            // (Receiver)
	void init_recv_pkt_accounting();                        // (Receiver)

	double rate[10];        // Transmission rates associated to scale values
	double interval_;      // Application data packet transmission interval
	int pktsize_;          // Application data packet size
	int running_;          // If 1 application is running
	int seq_;              // Application data packet sequence number
	int scale_;            // Media scale parameter
	pkt_acc p_acc;
	SendTimer snd_timer_;  // SendTimer
	AckTimer  ack_timer_;  // AckTimer

};

MmApp::MmApp() : running_(0), snd_timer_(this), ack_timer_(this)
{
  bind_bw("rate0_", &rate[0]);
  bind_bw("rate1_", &rate[1]);
  bind_bw("rate2_", &rate[2]);
  bind_bw("rate3_", &rate[3]);
  bind_bw("rate4_", &rate[4]);
  bind_bw("rate5_", &rate[5]);
  bind_bw("rate6_", &rate[6]);
  bind_bw("rate7_", &rate[7]);
  bind_bw("rate8_", &rate[8]);
  bind_bw("rate9_", &rate[9]);
  bind("pktsize_", &pktsize_);
  bind_bool("random_", &random_);
}

int newApp::command(int argc, const char*const* argv)
{
  Tcl& tcl = Tcl::instance();

  if (argc == 3) {
    if (strcmp(argv[1], "attach-agent") == 0) {
      agent_ = (Agent*) TclObject::lookup(argv[2]);
      if (agent_ == 0) {
		tcl.resultf("no such agent %s", argv[2]);
		return(TCL_ERROR);
      }

      
      if(agent_->supportNew()) {
		agent_->enableNew();
      }
      else {
		tcl.resultf("agent \"%s\" does not support New Application", argv[2]);
		return(TCL_ERROR);
      }
      
      agent_->attachApp(this);
      return(TCL_OK);
    }
  }
  return (Application::command(argc, argv));
}





class SendTimer : public TimerHandler {
 public:
	SendTimer(newApp* t) : TimerHandler(), t_(t) {}
	inline virtual void expire(Event*)
	{

	}
 protected:
	newApp* t_;
};

class AckTimer : public TimerHandler {
 public:
	AckTimer(newApp* t) : TimerHandler(), t_(t) {}
	inline virtual void expire(Event*);
 protected:
	newApp* t_;
};



