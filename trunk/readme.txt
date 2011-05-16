{*******************************************************************************
        单元名称：untASIOSvr.pas
        创建日期：2011-04-07 17:26:15
        创建者	  马敏钊
        功能:     ASIO 完成端口服务器通用封装
        当前版本：v1.1.0
        历史：
        v1.0.0 2011-04-07
                  创建本单元，对ASIO进行高效率的封装，
                  同时封装高效的数据处理模型
        v1.0.1 2011-04-20
                  修正了客户端退出时有时报异常的BUG
                  进过测试确定 在客户端发送大数据时不用手动分片发送
                  修改write过程的发送实现
        v1.0.2 2011-04-25
                  修正服务端因客户端导致异常，而影响其它连接的BUG。
                  修正服务端最后一个连接不被处理的BUG
        v1.0.2a 2011-05-07
                  修正TASIOCLIENT的 readinteger方法的一个bug，
                  感谢群友FlashDance反馈的BUG : )
                  修正服务端退出时的异常，修改通过killtask结束进程的方式
                  修正服务端因客户端长时间不发数据超时导致的异常
                  修正客户端用户名错误时，多次登录导致服务端异常
                  感谢群友小饶的测试和问题反馈

          v1.1.0 2011-05-16
                  修正多次异步投递可能导致的数据乱序（多个文件同时下载，导致乱序的问题）
                  优化底层库提高效率
********************************************************************************}

目录结构介绍

mmz-asio4delphi\性能测试程序   
      asio封装的性能测试程序，包含服务端和客户端以及相关源码

mmz-asio4delphi\聊天示例程序  
      一个简单的聊天示例程序，底层使用mmz-asio4delphi实现
			
mmz-asio4delphi\文件传输示例程序  
      一个简单的文件传输示例程序，基于聊天示例，底层使用mmz-asio4delphi实现

     
mmz-asio4delphi\AsioDLL  
      asio的c++动态库封装源码，包含vs2005和vs2003的项目文件

mmz-asio4delphi\untAsioSvr  
      mmz-asio4delphi的源码，包含对asio的高效率封装
      提供tcp服务端以及客户端接口
  
mmz-asio4delphi\远程数据库对象_ado_asio支持delphi全版本   
      Unidac远程对象的最新版本，底层使用mmz-asio4delphi实现

mmz-asio4delphi\远程数据库对象_uniDAC_ASIO版本    
      Ado远程对象的最新版本，底层使用mmz-asio4delphi实现
			
			
			
实现说明：

TAsioSvr 是最基本的服务端对象 
TBaseSocketServer 是更上层封装，主要增加了一些基本操作 如流收发，文件收发等接口
TCenterServer 是更上层封装，模拟处理用户登录 权限检查 事件处理 以及断开流程
TRmodbSvr  就是应用层了

如果要自己定义TCP服务端 可以选择从任意一层来继承 

客户端对象基本类似 
TAsioClient  是基本的客户端对象
TSocketClient 是更上层封装，主要增加了一些基本操作 如流收发，文件收发等接口，
TRmoClient  就是应用层了自动重连 心跳发送也是在这一层

----------------------------------------------------------------------------------------传说中的虫虫(22900104)  15:18:44
协议就很简单啊   头（4字节）|长度（4字节）|包体（不定长）
传说中的虫虫(22900104)  15:19:12
我ASIO服务端取的时候 就先取8个字节，然后再取包体
重新开始(704121401)  15:19:29
 具体什么包头代表啥意思，是自己定义？
传说中的虫虫(22900104)  15:19:34
包体里边是业务协议
传说中的虫虫(22900104)  15:20:10
这个协议是我 ASIO服务端用的， 具体的业务协议 在包体内定义
传说中的虫虫(22900104)  15:20:48
也就是客户端 发送任何一个数据包 都必须有头和长度
传说中的虫虫(22900104)  15:21:17
 SendAsioHead(8 + llen);
传说中的虫虫(22900104)  15:21:33
所以客户端和以前相比多了这个函数
传说中的虫虫(22900104)  15:21:38
其它都没变
静水流深(369859772)  15:22:09
每次发送之前先把内容长度加8发过去？
传说中的虫虫(22900104)  15:22:33
那个8也是包体的 数据
传说中的虫虫(22900104)  15:22:42
var
  llen, i: Integer;
  ls: string;
  Lend: integer;
  Litem: TSelectitems;
begin
  inc(Fsn);
  Lend := 0;
  ls := ISql;
  llen := length(isql);
  SendAsioHead(8 + llen);
传说中的虫虫(22900104)  15:22:51
var
  llen, i: Integer;
  ls: string;
  Lend: integer;
  Litem: TSelectitems;
begin
  inc(Fsn);
  Lend := 0;
  ls := ISql;
  llen := length(isql);
  SendAsioHead(8 + llen);
  WriteInteger(2);
  WriteInteger(llen);
  Write(ISql);
传说中的虫虫(22900104)  15:23:04
8 是   WriteInteger(2);   WriteInteger(llen);  这2个
静水流深(369859772)  15:23:32
这样啊
传说中的虫虫(22900104)  15:23:41
  多了一层协议 
传说中的虫虫(22900104)  15:23:49
服务端的处理和之前完全一样
静水流深(369859772)  15:24:14
嗯。服务端我看好像是没什么变化
传说中的虫虫(22900104)  15:24:49
如果是直接封装 TAsioSvr  那这层协议可以省掉
传说中的虫虫(22900104)  15:26:09
procedure TCenterServer.UserConn(ClientThread: TAsioClient; Iwantlen: integer);
var
  i, Lhead: Integer;
  LPrd: PRBaseCaserd;
  Lbuff: TPoolItem;
  IClient: TAsioClient;
begin
  IClient := ClientThread;
  if IClient.DeadTime > 0 then Exit;
  try
    if IClient.ConnState = Casio_State_Init then begin
      OnConning(ClientThread);
      if OnCheckLogin(ClientThread) then begin
        ClientThread.ConnState := Casio_State_Conned
      end
      else begin
        ClientThread.ConnState := Casio_State_DisConn;
        OnDisConn(ClientThread);
        ClientThread.Socket.Disconnect;
      end;
    end
    else if IClient.ConnState = Casio_State_Conned then begin
      //判断数据处理状态
      case IClient.RcvDataBuffer.State of //读取数据头
        CdataRcv_State_head: begin
            IClient.RcvDataBuffer.ReadInteger(true); //包头
            IClient.RcvDataBuffer.WantData := IClient.RcvDataBuffer.ReadInteger(true); //4个字节 //长度
            IClient.RcvDataBuffer.State := CdataRcv_State_Body; //读取包体
//        DeBug('收到数据<Currpost:%d ReadPos:%d NextSize:%d wantdata:%d>',
//          [IClient.RcvDataBuffer.CurrPost, IClient.RcvDataBuffer.ReadPos,
//          IClient.RcvDataBuffer.Memory.Position, IClient.RcvDataBuffer.WantData]);
          end;
        CdataRcv_State_len: begin //读取数据长度
            IClient.RcvDataBuffer.WantData := IClient.RcvDataBuffer.ReadInteger(true); //4个字节
            IClient.RcvDataBuffer.State := CdataRcv_State_Body;
//        DeBug('处理长度<Currpost:%d ReadPos:%d NextSize:%d wantdata:%d>',
//          [IClient.RcvDataBuffer.CurrPost, IClient.RcvDataBuffer.ReadPos,
//          IClient.RcvDataBuffer.Memory.Position, IClient.RcvDataBuffer.WantData]);
          end;
        CdataRcv_State_Body: begin //处理包体
           //IClient.RcvDataBuffer.ReadBuff(IClient.RcvDataBuffer.WantData); //4个字节
            IClient.RcvDataBuffer.WantData := 8;
            IClient.RcvDataBuffer.State := CdataRcv_State_head;
//        DeBug('处理包体<Currpost:%d ReadPos:%d NextSize:%d wantdata:%d>',
//          [IClient.RcvDataBuffer.CurrPost, IClient.RcvDataBuffer.ReadPos,
//          IClient.RcvDataBuffer.Memory.Position, IClient.RcvDataBuffer.wantdata]);
          {处理数据包}
            DataCase(IClient);
            
传说中的虫虫(22900104)  15:26:39
服务端之所以不变 是因为协议封装到父对象 TCenterServer里边了
静水流深(369859772)  15:26:41
 

是不是asioDataBuffer一次性读取的就包含上面发出的包头、包体长度和包体内容
而不是像dxsock每一个write对应一个read?
传说中的虫虫(22900104)  15:27:21
不是的  asio只要接收到数据就会 通知上层应用， 至于包头包体等处理 是我应用层来处理的
传说中的虫虫(22900104)  15:27:57
也就是粘包 或者收不够数据等等问题 是由我来处理的， 
传说中的虫虫(22900104)  15:28:08
交给应用层的时候 已经是接收到所有数据了
传说中的虫虫(22900104)  15:28:12
客户端也一样
传说中的虫虫(22900104)  15:29:57
包头|长度|包体 这样的协议可以支持任何传输内容
传说中的虫虫(22900104)  15:30:13
处理起来比较灵活
传说中的虫虫(22900104)  15:32:00
如果不喜欢这样的处理方式 也是可以从 TAsioSvr 直接继承 实现自己的协议处理
传说中的虫虫(22900104)  15:33:57
TAsioSvr 是最基本的服务端对象 
TBaseSocketServer 是更上层封装，主要增加了一些基本操作 如流收发，文件收发等接口
TCenterServer 是更上层封装，模拟处理用户登录 权限检查 事件处理 以及断开流程
TRmodbSvr  就是应用层了
传说中的虫虫(22900104)  15:34:36
如果要自己定义TCP服务端 可以选择从任意一层来继承 
传说中的虫虫(22900104)  15:36:12
客户端对象基本类似 
TAsioClient  是基本的客户端对象
TSocketClient 是更上层封装，主要增加了一些基本操作 如流收发，文件收发等接口，自动重连 心跳发送也是在这一层
TRmoClient  就是应用层了

传说中的虫虫(22900104)  15:36:51
哦不好意思 自动重连 心跳发送是 TRmoClient 应用层实现的

传说中的虫虫(22900104)  15:39:15
TAsioClient对象的
{阻塞方式发送数据}
    function Writeinteger(Iint: Integer; ITrans: boolean = true): Integer;
    function Write(Ibuffer: Pointer; Ilen: Integer): Integer; overload;
    function Write(Istr: AnsiString): Integer; overload;


    function WriteString(Istr: AnsiString): Integer;
    {阻塞方式接收数据}
    function Readinteger(Itrans: Boolean = true): integer;
    function ReadBuffer(Ibuffer: Pointer; Ilen: Integer): integer;
    function ReadStr(Ilen: Integer): AnsiString;
是作为客户端用的

传说中的虫虫(22900104)  15:39:18
    Socket: TAsioDataBuffer; //为兼容老程序所设置 属于RcvDataBuffer对象的指针
    RcvDataBuffer: TAsioDataBuffer; //数据buffer
传说中的虫虫(22900104)  15:39:38
而TAsioDataBuffer 是作为在服务端的连接的对象时调用的。
传说中的虫虫(22900104)  15:39:50
// 这些方法都是服务端时用的  2011-04-14 15:28:27   马敏钊
    function ReadInteger(IrcvGob: Boolean = false; ITrans: Boolean = True): Integer;
    function ReadStr(Ilen: integer; IrcvGob: Boolean = false): AnsiString;
    function ReadBuff(Ibuffer: Pointer; Ilen: integer; IrcvGob: Boolean = false):
      Integer;
    procedure Writeinteger(Iin: Integer; Ihtn: boolean = true);
    procedure Write(IBuffer: Pointer; Ilen: Integer); overload;
    procedure Write(IStr: AnsiString); overload;
    {断开连接}
    procedure Disconnect;
//------------------------------------------------------------------------------
传说中的虫虫(22900104)  15:40:18
因为客户端 和服务端 的偶共用了TAsioClient 对象
传说中的虫虫(22900104)  15:40:26
因为客户端 和服务端 都共用了TAsioClient 对象
传说中的虫虫(22900104)  15:42:36
换句话说 也就是 作为tcp客户端你可以直接创建TAsioClient 对象，要收发数据也是直接调用TAsioClient 下的readxxx或者writexxx方法。
但在tcp服务端，每个连接也是TAsioClient对象， 收发数据就要调用
TAsioClient.Socket.writexxx或readxxx 
传说中的虫虫(22900104)  15:42:51
就有这点区别：） 
传说中的虫虫(22900104)  15:44:58
基本说完了 呵呵 有疑问欢迎讨论
