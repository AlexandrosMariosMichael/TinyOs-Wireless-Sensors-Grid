#include "SimpleRoutingTree.h"

configuration SRTreeAppC @safe() { }
implementation{
	components SRTreeC;

#if defined(DELUGE) //defined(DELUGE_BASESTATION) || defined(DELUGE_LIGHT_BASESTATION)
	components DelugeC;
#endif

#ifdef PRINTFDBG_MODE
		components PrintfC;
#endif

		//Afairesi Serial 

	components MainC, LedsC, ActiveMessageC;
	components new TimerMilliC() as RoutingMsgTimerC;

	components new TimerMilliC() as Led0TimerC;
	components new TimerMilliC() as Led1TimerC;
	components new TimerMilliC() as Led2TimerC;

	components new TimerMilliC() as LostTaskTimerC;
	components new TimerMilliC() as NextEpochTimerC;
	components new TimerMilliC() as CollectionTimerC;
	
	components new AMSenderC(AM_ROUTINGMSG) as RoutingSenderC;
	components new AMSenderC(AM_COLLECTIONMSG) as CollectionSenderC; //Ta Notify eginan Collection

	components new AMReceiverC(AM_ROUTINGMSG) as RoutingReceiverC;
	components new AMReceiverC(AM_COLLECTIONMSG) as CollectionReceiverC;


	components new PacketQueueC(SENDER_QUEUE_SIZE) as RoutingSendQueueC;
	components new PacketQueueC(SENDER_QUEUE_SIZE) as CollectionSendQueueC;
	components new PacketQueueC(RECEIVER_QUEUE_SIZE) as CollectionReceiveQueueC;
	components new PacketQueueC(RECEIVER_QUEUE_SIZE) as RoutingReceiveQueueC;
	

	SRTreeC.Boot->MainC.Boot;
	SRTreeC.RadioControl -> ActiveMessageC;
	SRTreeC.Leds-> LedsC; 
	

	
	SRTreeC.RoutingMsgTimer->RoutingMsgTimerC;

	SRTreeC.Led0Timer-> Led0TimerC;	
	SRTreeC.Led1Timer-> Led1TimerC;
	SRTreeC.Led2Timer-> Led2TimerC;


	SRTreeC.LostTaskTimer->LostTaskTimerC;
	SRTreeC.NextEpochTimer->NextEpochTimerC; //Pros8iki kenourgiou timer
	SRTreeC.CollectionTimer->CollectionTimerC;
	
	SRTreeC.RoutingPacket->RoutingSenderC.Packet;
	SRTreeC.RoutingAMPacket->RoutingSenderC.AMPacket;
	SRTreeC.RoutingAMSend->RoutingSenderC.AMSend;
	SRTreeC.RoutingReceive->RoutingReceiverC.Receive;
	
	SRTreeC.CollectionPacket->CollectionSenderC.Packet;
	SRTreeC.CollectionAMPacket->CollectionSenderC.AMPacket;
	SRTreeC.CollectionAMSend->CollectionSenderC.AMSend;
	SRTreeC.CollectionReceive->CollectionReceiverC.Receive;

	SRTreeC.RoutingSendQueue->RoutingSendQueueC;
	SRTreeC.CollectionSendQueue->CollectionSendQueueC;
	SRTreeC.CollectionReceiveQueue->CollectionReceiveQueueC;
	SRTreeC.RoutingReceiveQueue->RoutingReceiveQueueC;
	
}
