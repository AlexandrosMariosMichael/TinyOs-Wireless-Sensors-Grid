#ifndef SIMPLEROUTINGTREE_H
#define SIMPLEROUTINGTREE_H

enum{
	SENDER_QUEUE_SIZE=5,
	RECEIVER_QUEUE_SIZE=10,
	AM_SIMPLEROUTINGTREEMSG=22,
	AM_ROUTINGMSG=22,
	AM_COLLECTIONMSG=32,
	SEND_CHECK_MILLIS=70000,
	TIMER_PERIOD_MILLI=150000,
	TIMER_FAST_PERIOD=200,
	TIMER_LEDS_MILLI=1000,

	TIMER_EPOCH_DURATION_MILLI=600000,
	MAX_DEPTH=32,
	TCT=10,
};
	const int EPOCH_WINDOW=TIMER_EPOCH_DURATION_MILLI/MAX_DEPTH;
/*
typedef nx_struct RoutingMsg
{
	nx_uint16_t senderID;
	nx_uint8_t depth;
} RoutingMsg;*/

typedef nx_struct RoutingMsg
{
	nx_uint16_t senderID;
	nx_uint8_t depth;

	nx_uint8_t RandChoice;
	nx_uint8_t FunctionRand;
	nx_uint8_t NumOfFunction[2];
	

} RoutingMsg;

typedef nx_struct CollectionMsg
{

	nx_uint16_t senderID;
	nx_uint16_t receiverID; //palio parentID //Afairesi depth axriasti pliroforia gia na metaferi
	
	nx_uint16_t max;
	nx_uint16_t count;
	nx_uint16_t sum;	
	
}CollectionMsg;






typedef nx_struct msg_with_one_data
{

	nx_uint16_t senderID;
	nx_uint16_t receiverID; //palio parentID //Afairesi depth axriasti pliroforia gia na metaferi

	nx_union  {
 	nx_uint16_t max;
	nx_uint16_t count;
	nx_uint16_t sum;
 	nx_uint16_t min;
 	nx_uint16_t heartbeat;
	}data1 ;

	
}msg_with_one_data;
/////////////////////////////////////////////////////////////////////////////////////////////////////
typedef nx_struct msg_with_two_data
{

	nx_uint16_t senderID;
	nx_uint16_t receiverID; //palio parentID //Afairesi depth axriasti pliroforia gia na metaferi

	nx_union  {
 	nx_uint16_t max;
	nx_uint16_t count;
	nx_uint16_t sum;
 	nx_uint16_t min;
	}data1 ;


	nx_union  {
 	nx_uint16_t max;
	nx_uint16_t count;
	nx_uint16_t sum;
 	nx_uint16_t min;
	}data2 ;

	
}msg_with_two_data;


typedef nx_struct msg_with_three_data
{

	nx_uint16_t senderID;
	nx_uint16_t receiverID; //palio parentID //Afairesi depth axriasti pliroforia gia na metaferi

	nx_union  {
 	nx_uint16_t max;
	nx_uint16_t count;
	nx_uint16_t sum;
 	nx_uint16_t min;
	}data1 ;

	nx_union  {
 	nx_uint16_t max;
	nx_uint16_t count;
	nx_uint16_t sum;
 	nx_uint16_t min;
	}data2 ;

	nx_union  {
 	nx_uint16_t max;
	nx_uint16_t count;
	nx_uint16_t sum;
 	nx_uint16_t min;
	}data3 ;

	
}msg_with_three_data;
/////////////////////////////////////////////////////////////////////////////////////////////////////
/*typedef nx_struct msg_with_four_data
{

	nx_uint16_t senderID;
	nx_uint16_t receiverID; //palio parentID //Afairesi depth axriasti pliroforia gia na metaferi

	Data data1;
	Data data2;
	Data data3;
	Data data4;

	
}msg_with_four_data;*/






















#endif












