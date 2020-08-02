
package smtp_offline;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.InetAddress;
import java.net.Socket;
import java.net.SocketException;
import java.net.SocketTimeoutException;
import java.net.UnknownHostException;
import java.util.ArrayList;
import java.util.List;


public class SMTP_Offline {

    /**
     * @param args the command line arguments
     */
    
    public static String serverMessage,userMessage = "",subject = "",ownEmail = "",receiverEmail = "";
    public static ArrayList<String> cc=new ArrayList<>();
    
    public static int myParse(String str)
    {
        String temp=str.substring(0, 3);
        int ret=Integer.parseInt(temp);
        return ret;
    }
    
    public static void take_input() throws IOException
    {
        BufferedReader input=new BufferedReader(new InputStreamReader(System.in));
        
        System.out.println("Enter your Email Address:");
        ownEmail=input.readLine();
        
        System.out.println("Enter receiver Email Address:");
        receiverEmail=input.readLine();
        
        System.out.println("Do you want to add more recipients i.e. CC ? (Y/N)");
        String answer=input.readLine();
        if(answer.equalsIgnoreCase("y"))
        {
            System.out.println("Keep entering the email addresses and write '#' when finished.");
            while(!"#".equals(answer= input.readLine()))
            {
                    cc.add(answer);
            }
        }
       // System.out.println("Ending..");
        
        
//        System.out.println("Enter mail Subject");
//        sub=input.readLine();
//        
//        System.out.println("Enter mail message");
//        String line;
//        while(!".".equals(line= input.readLine()))
//        {
//            body=body+line+"\n";
//        }   
        
    }
    
    public static void init()
    {
        userMessage = ""; subject = ""; ownEmail = ""; receiverEmail = "";
        cc.clear();
    }
    
    public static String command_parse(String input)
    {
        String output="";
        if(input.equalsIgnoreCase("MAIL")) output="MAIL FROM:<"+ownEmail+">";
        else if(input.equalsIgnoreCase("RCPT")) output="RCPT TO:<"+receiverEmail+">";
        else if(input.equalsIgnoreCase("DATA")) output="DATA";
        else if(input.equalsIgnoreCase("RSET")) output="RSET";
        else if(input.equalsIgnoreCase("QUIT")) output="QUIT";
        return output;
    }
    
    public static void main(String[] args) throws UnknownHostException, IOException {
        // TODO code application logic here
        
        take_input();
        
        String mailServer = "webmail.buet.ac.bd";
        InetAddress mailHost = InetAddress.getByName(mailServer);
        //InetAddress mailHost = InetAddress.getLocalHost();
        InetAddress localHost = InetAddress.getLocalHost();
        Socket smtpSocket = new Socket(mailHost,587);
        smtpSocket.setSoTimeout(20000);
        //System.out.println("Here");
        BufferedReader in =  new BufferedReader(new InputStreamReader(smtpSocket.getInputStream()));
        PrintWriter pr = new PrintWriter(smtpSocket.getOutputStream(),true);
        String initialID = in.readLine();
        System.out.println("Server: "+initialID); 
        //pr.println("HELO "+localHost.getHostName());
        //pr.flush();
        //String welcome = in.readLine();
        //System.out.println(welcome); 
        
        
        BufferedReader inConsole=new BufferedReader(new InputStreamReader(System.in));
        
        String state="begin";
        String reply="";
        int rcptCount=cc.size()+1;
        int rcptSet=0;
       
        
        while(true)
        {
            try{
                if(state.equalsIgnoreCase("begin"))
            {
                
                System.out.println("Say Hello to proceed");
                String input=inConsole.readLine();
                
                if(input.equalsIgnoreCase("hello"))
                {
                    pr.println("HELO "+localHost.getHostName());
                    pr.flush();
                    
                    try
                    {
                        serverMessage = in.readLine();
                    } catch(SocketTimeoutException s)
                    {
                        System.out.println("Timed out");
                    }
                    
                    
                    System.out.println("Server: "+serverMessage); 
                    if(myParse(serverMessage)==250) state="wait";
                    else if(myParse(serverMessage)==221)
                    {
                        System.out.println("Connection closed.");
                        smtpSocket.close();
                        break;
                    }
                    else System.out.println("It didn't proceed. Try again");
                }
                else System.out.println("Incorrect input. Try again.");
            }
            
            else if(state.equalsIgnoreCase("wait"))
            {
                
                
                System.out.println("\nEnter the command. (MAIL, RCPT, DATA, RSET, QUIT etc)");
                System.out.println("[Sender email is not confirmed yet, MAIL suggested]\n");
                
                reply=inConsole.readLine();
                String command=command_parse(reply);
                pr.println(command);
                pr.flush();
                try
                {
                    serverMessage = in.readLine();
                } catch(SocketTimeoutException s)
                {
                    System.out.println("Timed out");
                }
                System.out.println("Server: "+serverMessage);
                
                if(myParse(serverMessage)==250)
                {
                    if(command.equals("RSET"))
                    {
                        System.out.println("Would you like to reset the input emails? (y/n");
                        reply=inConsole.readLine();
                        if(reply.equalsIgnoreCase("y")) take_input();
                        state="wait"; 
                    }
                        
                    else state="envelope";
                }
                else if(myParse(serverMessage)==221)
                {
                    System.out.println("Connection closed.");
                    smtpSocket.close();
                    break;
                }    
                else System.out.println("Invalid command try again.");
            }
            
            else if(state.equalsIgnoreCase("envelope"))
            {
                
                System.out.println("\nEnter the command. (MAIL, RCPT, DATA, RSET, QUIT etc)");
                if(rcptSet==0) System.out.println("[Receiver email is not confirmed yet, RCPT suggested]\n");
                else if(rcptCount>0) System.out.println(rcptCount+" more receivers to be confirmed. RCPT suggested, otherwise mail would be delivered excluding them");
                else
                {
                    state="rcptSet";
                    continue;
                }
                
                reply=inConsole.readLine();
                String command=command_parse(reply);
                
                
                if(reply.startsWith("RCPT"))
                {
                    if(rcptCount==cc.size()+1) command="RCPT TO:<"+receiverEmail+">";
                    else command="RCPT TO:<"+cc.get(rcptCount-1)+">";
                }
                
                
                
                pr.println(command);
                pr.flush();
                try
                {
                    serverMessage = in.readLine();
                } catch(SocketTimeoutException s)
                {
                    System.out.println("Timed out");
                }
                System.out.println(serverMessage); 
                if(myParse(serverMessage)==250)
                {
                    if(command.equals("RSET"))
                    {
                        System.out.println("Would you like to reset the input emails? (y/n");
                        reply=inConsole.readLine();
                        if(reply.equalsIgnoreCase("y")) take_input();
                        state="wait"; 
                    }
                    else
                    {
                        rcptSet=1;
                        rcptCount--;
                    }
                    
                }
                else if(myParse(serverMessage)==221)
                {
                    System.out.println("Connection closed.");
                    smtpSocket.close();
                    break;
                }
                else
                {
                    System.out.println("Invalid command or error");
                }
                    
                
            }
            
            else if(state.equalsIgnoreCase("rcptSet"))
            {
                
                System.out.println("Enter the command. (MAIL, RCPT, DATA, RSET, QUIT etc)");
                System.out.println("All receivers confirmed, DATA suggested");
                
                reply=inConsole.readLine();
                String command=command_parse(reply);
                
                pr.println(command);
                pr.flush();
                try
                {
                    serverMessage = in.readLine();
                } catch(SocketTimeoutException s)
                {
                    System.out.println("Timed out");
                }
                System.out.println(serverMessage); 
                
                if(command.equals("RSET") && myParse(serverMessage)==250)
                {
                        System.out.println("Would you like to reset the input emails? (y/n");
                        reply=inConsole.readLine();
                        if(reply.equalsIgnoreCase("y")) take_input();
                        state="wait"; 
                    
                }
                if(myParse(serverMessage)==354) state="writing";
                else if(myParse(serverMessage)==221)
                {
                    System.out.println("Connection closed.");
                    smtpSocket.close();
                    break;
                }
                else System.out.println("Invalid command or error");
                
            }
            
            else if(state.equalsIgnoreCase("writing"))
            {
                System.out.println("Enter email subject");
                subject=inConsole.readLine();
                
                System.out.println("Enter your message");
                //userMessage=inConsole.readLine();
                String line;
                while(!".".equals(line= inConsole.readLine()))
                {
                    userMessage=userMessage+line+"\n";
                }
                state="deliver";
                
            }
            
            else if(state.equalsIgnoreCase("deliver"))
            {
                String mail= "Subject: "+subject+"\n"+"From: "+ownEmail+"\n"+"To: "+receiverEmail+"\n";
                
                for(int i=0;i<cc.size();i++)
                {
                    if(i==0) mail+="Cc: ";
                    mail=mail+cc.get(i);
                    if(i!=cc.size()-1) mail=mail+", ";
                }
                
                mail=mail+"\n\n"+userMessage+"\r\n.\r\n";
                pr.print(mail);
                pr.flush();
                try
                {
                    serverMessage = in.readLine();
                } catch(SocketTimeoutException s)
                {
                    System.out.println("Timed out");
                }
                System.out.println(serverMessage); 
                if(myParse(serverMessage)==250)
                {
                    state="wait";
                    System.out.println("Message delivered\n");
                    
                }
            }
            }
            catch(SocketException se){
                System.err.println("Socket timed out");
                break;
            }
            
            
            
        }
        
    }
    
}
