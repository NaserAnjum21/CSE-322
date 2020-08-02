/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package http_offline;

import java.io.BufferedInputStream;
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;

public class HTTP_Offline {

    public static void main(String[] args) throws IOException {
        // TODO code application logic here

        int PORT = 6789;
        int count = 1;

        ServerSocket serverConnect = new ServerSocket(PORT);
        System.out.println("Server started.\nListening for connections on port : " + PORT + " ...\n");
        while (true) {

            Socket s = serverConnect.accept();
            ServerThread st = new ServerThread(s, count);

            Thread t = new Thread(st);
            t.start();
            count++;

        }

    }
}

class ServerThread implements Runnable {

    private Socket socket;
    private InputStream is;
    private OutputStream os;

    private int id;

    public ServerThread(Socket s, int id) {
        try {
            socket = s;
            is = s.getInputStream();
            os = s.getOutputStream();
            this.id = id;
        } catch (IOException ex) {
            System.err.println("Error with connection.");
        }
    }

    public String parse_filename(String str) {
        String[] words = str.split(" ");
        return words[1].substring(1);
    }
    
    public String find_MIME_type(String fname)
    {
        String ret="";
        if(fname.endsWith("jpg")) ret="image/jpg";
        else if(fname.endsWith("jpeg")) ret="image/jpeg";
        else if(fname.endsWith("png")) ret="image/png";
        else if(fname.endsWith("bmp")) ret="image/bmp";
        else if(fname.endsWith("gif")) ret="image/gif";
        else if(fname.endsWith("html")) ret="text/html";
        else if(fname.endsWith("txt")) ret="text/plain";
        else if(fname.endsWith("pdf")) ret="application/pdf";
        
        return ret;
    }

    @Override
    public void run() {
        BufferedReader in = new BufferedReader(new InputStreamReader(is));
        PrintWriter pr = new PrintWriter(os);

        String fileName = "C:/Users/ASUS/Documents/NetBeansProjects/HTTP_Offline/src";
        String html_code = "";
        String input;
        
        

        while (true) {

            try {
                //String input = in.readLine();
                File logFile=new File("log.txt");
                BufferedWriter writer = new BufferedWriter(new FileWriter(logFile,true));
                
                FileWriter outputStream = new FileWriter(logFile,true);
                
                
                if ((input = in.readLine()) != null) {
                    //System.out.println("Hello");
                    //continue;
                    //System.out.println(input);
                    byte[] strToBytes = (input+"\r\n").getBytes();
                    //outputStream.write(strToBytes);
                    outputStream.write(input+"\r\n");
                    
                    //writer.append(input+"\n");
                    

                    String[] words = input.split(" ");

                    

                    if (words[0].equalsIgnoreCase("GET") || words[0].equalsIgnoreCase("POST")) {
                        fileName = words[1].substring(1);

                        if (words[1].equalsIgnoreCase("/")) {
                            fileName = "index.html";
                        }

                        // System.out.println(words[1]);
                        try {
                            File file = new File(fileName);
                            BufferedReader fbr = new BufferedReader(new FileReader(file));
                            Boolean isWebPage=false;
                            
                            FileInputStream fis = new FileInputStream(file);
                            BufferedInputStream bis = new BufferedInputStream(fis);
                            
                            
                            String mimeType=find_MIME_type(fileName);
                            
                            if(fileName.endsWith("html"))
                            {
                                isWebPage=true;
                                String line = "";
                                html_code = "";
                                while ((line = fbr.readLine()) != null) {
                                    html_code += (line + "\r\n");
                                }
                            }
                            
                            //System.out.println(html_code);
                            
                            StringBuilder allResponse = new StringBuilder();
                                while (in.ready()) {
                                    allResponse.append((char) in.read());
                                }
                                String data=allResponse.toString();
                            
                            if(input.startsWith("POST") && isWebPage)
                            {
                                
                                String post_data=data.substring(data.lastIndexOf("\n"));
                                String[] temp=post_data.split("=");
                                
                                String name="";
                                if(temp.length>1)
                                {
                                    name=temp[1];
                                    name= URLDecoder.decode(name, StandardCharsets.UTF_8.name());
                                }
                                
                                
                                int idx=html_code.indexOf("Post->");
                                idx=idx+6;
                                String mod_html=html_code.substring(0,idx)+name+"\r\n"+html_code.substring(idx,html_code.length());
                                html_code=mod_html;
                                
                                
                                //System.out.println(name);
                            }
                            
                            //System.out.println(data);
                            outputStream.write(data+"\r\n");
                            

                            byte[] codes = null;
                            
                            
                            if(isWebPage) codes=html_code.getBytes("UTF-8");
                            else codes=Files.readAllBytes(file.toPath());

                            String header = "HTTP/1.1 200 OK\r\n";
                            header += ("Content-Length: " + codes.length + "\r\n");
                            header += "Content-Type: "+ mimeType+ "; charset=UTF-8\r\n\r\n";

                            byte[] httpHeader = header.getBytes("UTF-8");

                            os.write(httpHeader);
                            os.write(codes);
                            os.flush();

                        } catch (FileNotFoundException e) {
                            System.err.println("File not found");

                            html_code = "<html><body> 404 Not Found  </body></html>";

                            byte[] codes = html_code.getBytes("UTF-8");

                            String header = "HTTP/1.1 404 Not Found\r\n";
                            header += ("Content-Length: " + codes.length + "\r\n");
                            header += "Content-Type: text/html; charset=UTF-8\r\n\r\n";

                            byte[] httpHeader = header.getBytes("UTF-8");

                            os.write(httpHeader);
                            os.write(codes);
                            os.flush();

                        }

                        System.out.println("From id " + id + "-> Input : " + input);

                    }
                    this.is.close();
                    this.os.close();
                    this.socket.close();
                    writer.close();
                    outputStream.close();
                    break;

                } else {
                    this.is.close();
                    this.os.close();
                    this.socket.close();
                    writer.close();
                    outputStream.close();
                    break;

                }

            } catch (IOException ex) {
                System.err.println("Problem with input output");
            }
        }

    }

}
