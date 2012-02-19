#ifndef __MAIN_H__
#define __MAIN_H__

#include <windows.h>

/*  To use this exported function of dll, include this header
 *  in your project.
 */

#ifdef BUILD_DLL
    #define DLL_EXPORT __declspec(dllexport)
#else
    #define DLL_EXPORT __declspec(dllimport)
#endif


#ifdef __cplusplus
extern "C"
{
#endif



DLL_EXPORT int Asio_init(int iport);

DLL_EXPORT int Asio_SvrRun();

DLL_EXPORT int Asio_Uninit(int iport);

DLL_EXPORT int Asio_SetCallback(int ikind,int ifun);

DLL_EXPORT int Asio_senddata(int ikind,int* isocket,char * ibuff,int ilen);

DLL_EXPORT int Asio_closesocket(int* isocket);

DLL_EXPORT int Asio_Client_init(int* ipobj);

DLL_EXPORT int Asio_Client_conntosvr(int*  isocket,char* iip,int iport,int iuserdata);

DLL_EXPORT int Asio_Client_DisConn(int*   isocket);

DLL_EXPORT int Asio_Client_Free(int*  isocket);

DLL_EXPORT int Asio_Client_senddata(int*  isocket,char * ibuff,int ilen);

DLL_EXPORT int Asio_Client_readdata(int* isocket,char * ibuff,int ilen);

DLL_EXPORT int Asio_Client_Asreaddata(int* isocket,char * ibuff,int ilen,int iuserdata);



#ifdef __cplusplus
}
#endif

#endif // __MAIN_H__
