// Svr_intf.cpp : Defines the initialization routines for the DLL.
//

#include "stdafx.h"
#include "Svr_intf.h"
#include <iostream>
#include <boost/bind.hpp>
#include <boost/asio.hpp>
#include <windows.h>
#include <List>


using boost::asio::ip::tcp;
using std::cout;

#define DllExport __declspec(dllexport);




bool iscreate=false;
bool isfinished=false;
int gport;
class session;
class server;
boost::asio::io_service io_service; 
boost::asio::deadline_timer* lt;
server* s;



std::list<session*> deadlist;
std::list<session*>::iterator deadlist_Iter,deadlist_Iter2;
CRITICAL_SECTION criCounter;

//回调函数设置
typedef void (CALLBACK* Cb_OnNewConn)(int ipsocket,const char* ipeerip,int ipeerport,int* iuserdata,int* ireadlen);
typedef void (CALLBACK* Cb_OnDisConn)(int iuserdata);
typedef void (CALLBACK* Cb_Onreaddata)(char* ibuff,int ilen,int iuserdata,int* ireadlen);
typedef void (CALLBACK* Cb_Onwritedata)(int iuserdata,int iuser2);

Cb_OnNewConn Callback_NewConn;
Cb_OnDisConn Callback_DisConn;
Cb_Onreaddata Callback_readdata;
Cb_Onwritedata Callback_writedata;



class session
{
public:
  int readlen;
  int userdata;
  int deadtime;
  enum { max_length = 1024};
  char data_[max_length];
  

  session(boost::asio::io_service& io_service)
    : socket_(io_service)
  {
	  //data_[0]='a';
	  //data_[1]='b';
	  //data_[2]='1';
	   readlen=0;
	  userdata=0;
  }
  ~session()
  {
	  socket_.close();
	 // delete socket_;
  }

  tcp::socket& socket()
  {
    return socket_;
  }

  void start()
  {	  
    socket_.async_read_some(boost::asio::buffer(data_, max_length),
        boost::bind(&session::handle_read, this,
          boost::asio::placeholders::error,
          boost::asio::placeholders::bytes_transferred));
  }

  void handle_read(const boost::system::error_code& error,
      size_t bytes_transferred)
  {
  //  std::cout << "read some len:" << bytes_transferred <<  "\n" ; 
    if (!error)
    {
	
	  try
	  {
	  if(Callback_readdata!=NULL)
	  {
		 Callback_readdata(data_,bytes_transferred, userdata,&readlen);		 

	  }
	  }
	  catch(...)
	  {
	  }

	  if(userdata!=0)
	  {
      socket_.async_read_some(boost::asio::buffer(data_, max_length),
          boost::bind(&session::handle_read, this,
            boost::asio::placeholders::error,
            boost::asio::placeholders::bytes_transferred));
	  }
	  else{
	    socket_.close();
		 if(Callback_DisConn!=NULL)
		{
		  Callback_DisConn(userdata);
		}
	    delete this;
	  }
    }
    else
    {

	  socket_.close();
 	 // cout << "socket error " << error <<  "\n" ; 
	  if(Callback_DisConn!=NULL)
	  {
		  Callback_DisConn(userdata);
	  }
	  
       delete this;
    }
  }

  void handle_write(const boost::system::error_code& error,int iuser,int iuser2)
  {
    if(Callback_writedata!=NULL)
	{
	//	 std::cout << "write ok " << iuser <<  "\n" ; 
		 Callback_writedata(iuser,iuser2);
	}
    if (!error)
    {
       
    }
    else
    {
	  socket_.close();	
	  if(Callback_DisConn!=NULL)
	  {
		 Callback_DisConn(userdata);
	  }
    
	 
	   delete this;
    }
  }

private:
  tcp::socket socket_;


};

class server
{
public:
  server(boost::asio::io_service& io_service, short port)
    : io_service_(io_service),
      acceptor_(io_service, tcp::endpoint(tcp::v4(), port))
  {
	//创建临界区
   InitializeCriticalSection(&criCounter);

    session* new_session = new session(io_service_);
	
    acceptor_.async_accept(new_session->socket(),
        boost::bind(&server::handle_accept, this, new_session,
			boost::asio::placeholders::error
		  ));
  }
  ~server()
  {
	   //删除临界区
   DeleteCriticalSection(&criCounter);

  }
  void handle_accept(session* new_session,   
	     const boost::system::error_code& error
	  )
  {
	   int lbuf;
 //	cout << "some one conned ok \n" ; 
    if (!error)
    { 
	  if(Callback_NewConn!=NULL)
	  {
		 
		  lbuf=(int)(new_session);
		//  std::cout <<"socket addr:"<<lbuf << "\n" ; 
		//   cout <<"IP:"<<new_session->socket().remote_endpoint().address().to_string()<< " port:"<<new_session->socket().remote_endpoint().port()<<" \n" ; 
	  		/*  std::cout <<"userdata:"<<&new_session->userdata<< "\n" ; 
		  std::cout <<"readlen:"<<&new_session->readlen<< "\n" ; */
	
		  Callback_NewConn(lbuf,new_session->socket().remote_endpoint().address().to_string().c_str(),
			  new_session->socket().remote_endpoint().port(),
			  &new_session->userdata,
			  &new_session->readlen);
	 
		  new_session->start();
		  new_session = new session(io_service_);	
		 // //删除超时的sesson
		 // int i;
		 // for (deadlist_Iter=deadlist.begin(); deadlist_Iter !=deadlist.end(); ++deadlist_Iter)
			//{
			//	i= (*deadlist_Iter)->deadtime;
			//	i=GetTickCount() -i;
			// 
			//	if ( i > 3000)
			//	{
			//	       //用pos2来保存pos指针
			//	  deadlist_Iter2=deadlist_Iter;
			//	  deadlist_Iter++;
			//	  deadlist.erase(deadlist_Iter2);
			//	  delete (*deadlist_Iter);
			//	 }
			//}

	  }
      acceptor_.async_accept(new_session->socket(),
          boost::bind(&server::handle_accept, this, new_session,
            boost::asio::placeholders::error));
	/*  session* lp=(session*)(lbuf);	
	  boost::asio::async_write(lp->socket() ,
          boost::asio::buffer(new_session->data_, 4),
          boost::bind(&session::handle_write, 
		  new_session,
            boost::asio::placeholders::error,
			1
			));*/
		
    }
    else
    {
      delete new_session;
    }
  }

private:

  boost::asio::io_service& io_service_;
  tcp::acceptor acceptor_;
};


void ontimer(const boost::system::error_code& /*e*/)
{  
	if(isfinished==false)
	{
		lt->expires_from_now(boost::posix_time::seconds(1));
		lt->async_wait(boost::bind(ontimer,boost::asio::placeholders::error));  
	}
}




//typedef int (CALLBACK* fPlayerlst)(char* ibuff,int i);
//typedef int (CALLBACK* frecordlst)(char* ibuff,int i);

DllExport int Asio_init(int iport)
{		
   if(iscreate==false)
   {
	 /*  AllocConsole();
	freopen( "CONOUT$", "w", stdout ); 
    freopen( "CONOUT$", "w", stderr ); 
    freopen( "CONIN$", "r", stdin ); 
     cout << "init \n" ;*/
		gport=iport;
	    iscreate=true;
		if(iport==0)
		 //server s(io_service, iport); 
		//else 
		{
		  lt=new boost::asio::deadline_timer(io_service,boost::posix_time::seconds(1));  
		  lt->expires_from_now(boost::posix_time::seconds(1));
		  lt->async_wait(boost::bind(ontimer,boost::asio::placeholders::error));    
		}
		return 0;	
   }
//
//if (access("plog", 0) == 0)
//{
    
//}
}

DllExport int Asio_SvrRun()
{
	if(gport!=0)
	{
		s=new server(io_service,gport);
	}
	try
	{
	io_service.run();
	}
	catch(...)
	{
	}
	delete s;
	
	if(gport==0){ 
		Sleep(1000);
		delete lt;
	}

	return 0;	
}


 


DllExport int Asio_Uninit(int iport)
{
	if(gport==0){ 
      lt->cancel();
	}
	io_service.stop();
	isfinished=true;
 	return 0;	
}

DllExport int Asio_SetCallback(int ikind,int ifun)
{
	if(ikind==1)
		Callback_NewConn=(Cb_OnNewConn)ifun;
	else if(ikind==2)
		Callback_DisConn=(Cb_OnDisConn)ifun;
	else if(ikind==3)
		Callback_readdata=(Cb_Onreaddata)ifun;
	else if(ikind==4)
		Callback_writedata=(Cb_Onwritedata)ifun;
 	return 0;	
}

DllExport int Asio_senddata(int ikind,int isocket,char * ibuff,int ilen)
{
	 session* ltmp=(session*)isocket;

	boost::asio::async_write(ltmp->socket() ,
          boost::asio::buffer(ibuff, ilen),
          boost::bind(&session::handle_write, 
		  ltmp,
            boost::asio::placeholders::error,
			ltmp->userdata,
			ikind
			));
	return 0;
}

DllExport int Asio_closesocket(session * isocket)
{
	//isocket->userdata=0;//不允许再触发
	try
	{
	isocket->deadtime=GetTickCount();	
	isocket->socket().cancel();
	}
	catch(...)
	{}
	//EnterCriticalSection(&criCounter);
	//deadlist.push_back(isocket);
	//LeaveCriticalSection(&criCounter);

	//delete isocket;
	return 0;
}

DllExport int Asio_Client_init(int* ipobj)
{
	session*   new_session;
	new_session=new session(io_service); 
	*ipobj=int(new_session);
	return 0;	
}


DllExport int Asio_Client_conntosvr(session * isocket,char* iip,int iport,int iuserdata)
{
	//域名解析，只将域名解析为ipv4地址
	boost::asio::ip::tcp::endpoint ep(boost::asio::ip::address_v4::from_string(iip), iport); 
    //只连接一次    
    boost::system::error_code ec; 
	isocket->userdata=iuserdata;
    isocket->socket().connect(ep,ec);  
    if (ec)
      return 0;
	else 
	{
		isocket->socket().async_read_some(boost::asio::buffer(isocket->data_, isocket->max_length),
        boost::bind(&session::handle_read, isocket,
          boost::asio::placeholders::error,
          boost::asio::placeholders::bytes_transferred));  
	  return 1;
	}
    
}

DllExport int Asio_Client_DisConn(session * isocket)
{
	//isocket->userdata=0;//不允许再触发
	try
	{
		isocket->deadtime=GetTickCount();
		isocket->socket().cancel();	
		boost::system::error_code ignored_ec;  
		isocket->socket().shutdown(boost::asio::ip::tcp::socket::shutdown_both, ignored_ec);	
	}
	catch(...)
	{
	}
	return 0;	
}

DllExport int Asio_Client_Free(session * isocket)
{
	delete isocket;
	return 0;	
}



DllExport int Asio_Client_senddata(session * isocket,char * ibuff,int ilen)
{
	boost::system::error_code ignored_error;
      boost::asio::write(isocket->socket(), boost::asio::buffer(ibuff,ilen),
          boost::asio::transfer_all(), ignored_error);
    if(ignored_error)
	  return 0;	
	else
	  return 1;	
}

DllExport int Asio_Client_readdata(session * isocket,char * ibuff,int ilen)
{
	boost::system::error_code ignored_error;
	ilen=isocket->socket().read_some(boost::asio::buffer(ibuff,ilen) , ignored_error);
    if(ignored_error)
	  return 0;	
	else
	  return ilen;		
}

DllExport int Asio_Client_Asreaddata(session * isocket,char * ibuff,int ilen,int iuserdata)
{
	isocket->userdata=iuserdata;
	isocket->socket().async_read_some(boost::asio::buffer(isocket->data_, isocket->max_length),
        boost::bind(&session::handle_read, isocket,
          boost::asio::placeholders::error,
          boost::asio::placeholders::bytes_transferred));   
	  return 0;	
}