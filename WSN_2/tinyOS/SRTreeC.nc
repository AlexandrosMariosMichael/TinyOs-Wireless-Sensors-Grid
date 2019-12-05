#include "SimpleRoutingTree.h"
#ifdef PRINTFDBG_MODE
	#include "printf.h"
#endif

module SRTreeC
{
	uses interface Boot;
	uses interface SplitControl as RadioControl;

	uses interface AMSend as RoutingAMSend;
	uses interface AMPacket as RoutingAMPacket;
	uses interface Packet as RoutingPacket;
	
	uses interface AMSend as CollectionAMSend;
	uses interface AMPacket as CollectionAMPacket;
	uses interface Packet as CollectionPacket;


	uses interface Leds;
	uses interface Timer<TMilli> as RoutingMsgTimer;

	uses interface Timer<TMilli> as Led0Timer;
	uses interface Timer<TMilli> as Led1Timer;
	uses interface Timer<TMilli> as Led2Timer;

	uses interface Timer<TMilli> as LostTaskTimer;
	uses interface Timer<TMilli> as NextEpochTimer;
	uses interface Timer<TMilli> as CollectionTimer;
	
	uses interface Receive as RoutingReceive;
	uses interface Receive as CollectionReceive;
	
	uses interface PacketQueue as RoutingSendQueue;
	uses interface PacketQueue as RoutingReceiveQueue;
	
	uses interface PacketQueue as CollectionSendQueue;
	uses interface PacketQueue as CollectionReceiveQueue;
}
implementation
{
	uint16_t  roundCounter;
	
	message_t radioRoutingSendPkt;
	message_t radioCollectionSendPkt;
	
	
	
	bool RoutingSendBusy=FALSE;
	bool CollectionSendBusy=FALSE;

	bool lostRoutingSendTask=FALSE;
	bool lostCollectionSendTask=FALSE;
	bool lostRoutingRecTask=FALSE;
	bool lostCollectionRecTask=FALSE;
	
	uint8_t curdepth;
	uint16_t parentID;
	uint16_t avg;
	uint16_t sum;
	uint16_t max;
	uint16_t min;
	uint16_t var;
	uint16_t RandChoice;
	uint16_t FunctionRand;
	uint16_t count;
uint16_t temp_numf=0;
uint16_t sumSq;


uint16_t max_old;
uint16_t min_old;

uint16_t sum_old;
float comp_tct;
uint16_t tct_flag;
uint16_t heartbeat_count;
uint16_t heartbeat;
uint16_t tct_notify;

	uint16_t collection_length;

	uint8_t i;
	uint8_t flag;
	uint8_t NumOfFunction[2];
	uint8_t childrenNo[40];
	uint16_t childrenReadingSum[40];
	uint16_t childrenReadingMax[40];
	uint16_t childrenReadingMin[40];
	uint16_t childrenReadingCount[40];

	uint16_t childrenNotifyTct[40];
	uint16_t childrenHeartbeat[40];

	bool childrenAnswered[40];
	bool my_parent_recognised_me[40];
	
	
	task void sendRoutingTask();
	task void sendCollectionTask();
	task void receiveRoutingTask();
	task void receiveCollectionTask();
	

			
	event void Led0Timer.fired()
	{
		call Leds.led0Off();
	}
	event void Led1Timer.fired()
	{
		call Leds.led1Off();
	}
	event void Led2Timer.fired()
	{
		call Leds.led2Off();
	}
	


	void setLostRoutingSendTask(bool state)
	{
		atomic{
			lostRoutingSendTask=state;
		}
		if(state==TRUE)
		{
			//call Leds.led2On();
		}
		else 
		{
			//call Leds.led2Off();
		}
	}
	
	void setLostCollectionSendTask(bool state)
	{
		atomic{
		lostCollectionSendTask=state;
		}
		
		if(state==TRUE)
		{
			//call Leds.led2On();
		}
		else 
		{
			//call Leds.led2Off();
		}
	}
	
	void setLostCollectionRecTask(bool state)
	{
		atomic{
		lostCollectionRecTask=state;
		}
	}
	
	void setLostRoutingRecTask(bool state)
	{
		atomic{
		lostRoutingRecTask=state;
		}
	}
	void setRoutingSendBusy(bool state)
	{
		atomic{
		RoutingSendBusy=state;
		}
		if(state==TRUE)
		{
			call Leds.led0On();
			call Led0Timer.startOneShot(TIMER_LEDS_MILLI);
		}
		else 
		{
			//call Leds.led0Off();
		}
	}
	
	void setCollectionSendBusy(bool state)
	{
		atomic{
		CollectionSendBusy=state;
		}
		
		if(state==TRUE)
		{
			call Leds.led1On();
			call Led1Timer.startOneShot(TIMER_LEDS_MILLI);
		}
		else 
		{
			//call Leds.led1Off();
		}
	}



	event void Boot.booted()
	{
		/////// arxikopoiisi radio kai serial
		//call RadioControl.start();
		
		setRoutingSendBusy(FALSE);
		setCollectionSendBusy(FALSE);


		srand((unsigned) time(NULL));

		roundCounter =0;  //Counter Epoxis
		NumOfFunction[0]=0;
		NumOfFunction[1]=0;
		RandChoice=0;
		FunctionRand=0;
		flag=0;
		tct_flag=0;
		sum_old=1;
		heartbeat_count=0;
		
		for(i=0; i<40; i++) //arxikopioisi pinaka metavliton gia palies times 
		{
			
			childrenNo[i]=-1;
			childrenReadingMax[i]=0;
			childrenReadingCount[i]=0;
			childrenReadingSum[i]=0;
			childrenAnswered[i]=FALSE;
			my_parent_recognised_me[i]=FALSE;
		}

		//arxikopioisi
		if(TOS_NODE_ID==0)
		{

			curdepth=0;
			parentID=0;
			dbg("Boot", "curdepth = %d  ,  parentID= %d \n", curdepth , parentID);

			RandChoice=rand()%(2+1-1)+1;
			//GLOABAL VARIABLE GIA 2.1 OR 2.2 (ME RAND) 
			if (RandChoice==1)
			{

				FunctionRand=rand()%(2+1-1)+1;//Poses sinartisis stelni
				for ( i = 0; i <= FunctionRand-1  ; ++i)
				{
					do{
						NumOfFunction[i]=rand()%(6+1-1)+1;//Pies sinartisis ine 1-SUM , 2-COUNT ,3-MAX ,4-MIN,5-AVG, 6-VARIANCE
					}while(NumOfFunction[0]==NumOfFunction[1]);
				}

				dbg("SRTreeC", "RandChoice=%d FunctionRand=%d NumOfFunction[0]=%d NumOfFunction[1]=%d \n",RandChoice,FunctionRand,NumOfFunction[0],NumOfFunction[1]);




			}else if (RandChoice==2)
			{
				/* code */
				//dbg("SRTreeC", " 2.2 NO IMPLEMENTATION YET\n");
																				// 1-SUM , 2-COUNT, 3-MAX , 4-MIN 
				FunctionRand=1;
				NumOfFunction[0]=rand()%(4+1-1)+1;
				NumOfFunction[1]=0;
				dbg("SRTreeC", " 1-SUM , 2-COUNT, 3-MAX , 4-MIN \n");
				dbg("SRTreeC", "NumOfFunction = %d \n",NumOfFunction[0]);
			}


		}
		else
		{
			curdepth=-1;
			parentID=-1;
			dbg("Boot", "curdepth = %d  ,  parentID= %d \n", curdepth , parentID);
		}
		call RadioControl.start();
		
	}
	
	event void RadioControl.startDone(error_t err)
	{
		
		if (err == SUCCESS)
		{
			dbg("Radio" , "Radio initialized successfully!!!\n");

			if (TOS_NODE_ID==0 )
			{
				call RoutingMsgTimer.startOneShot(TIMER_FAST_PERIOD); //starts after 20sec
				
			}
			call NextEpochTimer.startOneShot(TIMER_EPOCH_DURATION_MILLI);  //starts after 60 sec
		}
		else
		{
			dbg("Radio" , "Radio initialization failed! Retrying...\n");

			call RadioControl.start();
		}
	}
	
	event void RadioControl.stopDone(error_t err)
	{ 
		dbg("Radio", "Radio stopped!\n");

	}

	//3ekinai tin litourgia tin epoxis
	//Tipoma Metavliton sto telos ka8e epoxis 
	//Arxikopioisi metavliton ke ipologismos timer Collection gia ka8e epipedo 
	//3ekinai to timer gia Collection ka8os ke gia epomeni Epoxi
	event void NextEpochTimer.fired()
	{
		
		
		uint16_t collectionDelay;
		dbg("SRTreeC", "NextEpochTimer fired! \n");
		roundCounter+=1;
		if (TOS_NODE_ID==0)
		{
		
			//dbg("SRTreeC", "Epoch ended SUM=%d COUNT=%d MAX=%d MIN=%d AVG=%u Var= %u\n",sum,count,max,min,avg,var);//Sto telos ka8e epoxis tiponoume 

			 //Au3anoume metriti gia ka8e epoxi
			if(RandChoice==1)
			{
						if (FunctionRand==1 &&(NumOfFunction[0]<=4))///msg_with_one_data --- min,max,sum,count
						{
								if(NumOfFunction[0]==1)	dbg("SRTreeC", "Epoch ended SUM=%d \n",sum);//Sto telos ka8e epoxis tiponoume 
								if(NumOfFunction[0]==2)	 dbg("SRTreeC", "Epoch ended COUNT=%d \n",count);//Sto telos ka8e epoxis tiponoume 
								if(NumOfFunction[0]==3)  dbg("SRTreeC", "Epoch ended MAX=%d \n",max);//Sto telos ka8e epoxis tiponoume 
								if(NumOfFunction[0]==4)	 dbg("SRTreeC", "Epoch ended  MIN=%d \n",min);//Sto telos ka8e epoxis tiponoume 
						}
						if (  (FunctionRand==1 && NumOfFunction[0]>4)   || flag==1  )//msg_with_two_data --- avg or var 
						{
								if(flag==1)
								{
									if(  NumOfFunction[0]==5 || NumOfFunction[1]==5 ) //  (AVG,SUM or count) OR (SUM or count,AVG)
	 								dbg("SRTreeC", "Epoch ended AVG=%d  SUM=%d  COUNT=%d \n",avg,sum,count);//Sto telos ka8e epoxis tiponoume 
									if(  NumOfFunction[0]==6 ||NumOfFunction[1]==6) //  (VAR,SUM or count) OR (SUM or count,VAR)
									 dbg("SRTreeC", "Epoch ended VAR=%d  SUM=%d  COUNT=%d \n",var,sum,count);//Sto telos ka8e epoxis tiponoume 

								}else
								{
									if(  NumOfFunction[0]==5  ) //  (AVG,SUM or count) OR (SUM or count,AVG)
	 								dbg("SRTreeC", "Epoch ended AVG=%d \n",avg);//Sto telos ka8e epoxis tiponoume 
									if(  NumOfFunction[0]==6) //  (VAR,SUM or count) OR (SUM or count,VAR)
									 dbg("SRTreeC", "Epoch ended VAR=%d \n",var);//Sto telos ka8e epoxis tiponoume 
								}
						}


						if   (FunctionRand==2 && NumOfFunction[0]<=4 && NumOfFunction[1]<=4  )//msg_with_two_data --- min max sum count sindiasmi 
						{
						
							switch (NumOfFunction[0]){


								case 1: if(NumOfFunction[1]==2)dbg("SRTreeC", "Epoch ended SUM=%d COUNT=%d \n",sum,count);//Sto telos ka8e epoxis tiponoume
									if(NumOfFunction[1]==3)dbg("SRTreeC", "Epoch ended SUM=%d MAX=%d \n",sum,max);
									if(NumOfFunction[1]==4)dbg("SRTreeC", "Epoch ended SUM=%d MIN=%d \n",sum,min);
									 break;	
							
								case 2: if(NumOfFunction[1]==1)dbg("SRTreeC", "Epoch ended SUM=%d COUNT=%d \n",sum,count);
									if(NumOfFunction[1]==3)dbg("SRTreeC", "Epoch ended COUNT=%d MAX=%d \n",count,max);
									if(NumOfFunction[1]==4)dbg("SRTreeC", "Epoch ended COUNT=%d MIN=%d \n",count,min);
									 break;

								case 3: if(NumOfFunction[1]==1)dbg("SRTreeC", "Epoch ended SUM=%d MAX=%d \n",sum,max);
									if(NumOfFunction[1]==2)dbg("SRTreeC", "Epoch ended COUNT=%d MAX=%d \n",count,max);
									if(NumOfFunction[1]==4)dbg("SRTreeC", "Epoch ended MAX=%d MIN=%d \n",max,min);
									 break;
								case 4: if(NumOfFunction[1]==1)dbg("SRTreeC", "Epoch ended SUM=%d MIN=%d \n",sum,min);
									if(NumOfFunction[1]==2)dbg("SRTreeC", "Epoch ended COUNT=%d MIN=%d \n",count,min);
									if(NumOfFunction[1]==3)dbg("SRTreeC", "Epoch ended MAX=%d MIN=%d \n",max,min);
									 break;
							default :break;
							}					
						}//end if

						if (FunctionRand==2 && ( ( NumOfFunction[0]>4 && NumOfFunction[1]<=4 )  ||( NumOfFunction[0]<=4 && NumOfFunction[1]>4 ) ) )//msg_with_three_data --- ( min or max )and (avg or var)   ----- to (avg,sum) kai (var,sum) .... vlepe flag pio panw
						{
								if(NumOfFunction[0]==4 || NumOfFunction[1]==4  )//an kapio apo ta dio einai to min
								{
									  if(NumOfFunction[0]==5 || NumOfFunction[1]==5  )
											dbg("SRTreeC", "Epoch ended MIN=%d AVG=%d \n",min,avg);
										 if(NumOfFunction[0]==6 || NumOfFunction[1]==6  )
											dbg("SRTreeC", "Epoch ended MIN=%d VAR=%d \n",min,var);

								}		
								if(NumOfFunction[0]==3 || NumOfFunction[1]==3 )//an kapio apo ta dio einai to min
								{
									  if(NumOfFunction[0]==5 || NumOfFunction[1]==5  )
											dbg("SRTreeC", "Epoch ended MAX=%d AVG=%d \n",max,avg);
										 if(NumOfFunction[0]==6 || NumOfFunction[1]==6  )
											dbg("SRTreeC", "Epoch ended MAX=%d VAR=%d \n",max,var);

								}		

						}//end if 

			}
			if(RandChoice==2)
			{
								if(NumOfFunction[0]==1)	dbg("SRTreeC", "Epoch ended SUM=%d \n",sum);//Sto telos ka8e epoxis tiponoume 
								if(NumOfFunction[0]==2)	 dbg("SRTreeC", "Epoch ended COUNT=%d \n",count);//Sto telos ka8e epoxis tiponoume 
								if(NumOfFunction[0]==3)  dbg("SRTreeC", "Epoch ended MAX=%d \n",max);//Sto telos ka8e epoxis tiponoume 
								if(NumOfFunction[0]==4)	 dbg("SRTreeC", "Epoch ended  MIN=%d \n",min);//Sto telos ka8e epoxis tiponoume 
			}
 
		



			dbg("SRTreeC", "\n ##################################### \n");
			dbg("SRTreeC", "#######   Epoch   %u    ############## \n", roundCounter);
			dbg("SRTreeC", "#####################################\n");


			dbg("SRTreeC", "IM RUNNING QUERY ->  2.%d\n", RandChoice);
			dbg("SRTreeC", "NUMBER OF FUNCTIONS -> %d \n", FunctionRand);
			dbg("SRTreeC", "##### 1-SUM , 2-COUNT ,3-MAX ,4-MIN,5-AVG, 6-VARIANCE #####\n");
			dbg("SRTreeC", "NumOfFunction[0]=%d NumOfFunction[1]=%d \n",NumOfFunction[0],NumOfFunction[1]);
			dbg("SRTreeC", "###############################################\n");
						
		}
	
		//Arxikopioisi metavliton gia ka8e epoxi

		sum=0;
		if(NumOfFunction[0]==4 || NumOfFunction[1]==4)
		min=10000;
	else
		min=0;
		count=0;
		avg=0;
		max=0;
		flag=0;
		heartbeat_count=0;//midenizete giati petixe to tct
		//msg_with_one_data={,0};




if( ( NumOfFunction[0]==5 && ( NumOfFunction[1]== 1 || NumOfFunction[1]== 2 ) )    ||   ( ( NumOfFunction[0]== 1 || NumOfFunction[0 ]== 2 ) && NumOfFunction[1]==5 ) ) //  (AVG,SUM or count) OR (SUM or count,AVG)
	 		flag=1;
if( ( NumOfFunction[0]==6 && ( NumOfFunction[1]== 1 || NumOfFunction[1]== 2 ) )    ||   ( ( NumOfFunction[0]== 1 || NumOfFunction[0 ]== 2 ) && NumOfFunction[1]==6 ) ) //  (VAR,SUM or count) OR (SUM or count,VAR)
	 flag=1;


		//3ekinima collection ana epipedo 
	
		collectionDelay=((MAX_DEPTH-(curdepth+1))*EPOCH_WINDOW)/1000;	

		if(curdepth!=255){
		dbg("SRTreeC", "The COLLECTION at level :%d is starting in %d\n", curdepth, collectionDelay);
		call CollectionTimer.startOneShot(collectionDelay*1000);
		}


		call NextEpochTimer.startOneShot(TIMER_EPOCH_DURATION_MILLI);///starts after 60 sec epomeno collection=epomenes metrisis ka8e as8itira 



	}


	event void LostTaskTimer.fired()
	{
		if (lostRoutingSendTask)
		{
			post sendRoutingTask();
			setLostRoutingSendTask(FALSE);
		}
		
		if( lostCollectionSendTask)
		{
			post sendCollectionTask();
			setLostCollectionSendTask(FALSE);
		}
		
		if (lostRoutingRecTask)
		{
			post receiveRoutingTask();
			setLostRoutingRecTask(FALSE);
		}
		
		if ( lostCollectionRecTask)
		{
			post receiveCollectionTask();
			setLostCollectionRecTask(FALSE);
		}
	}





	event void RoutingAMSend.sendDone(message_t * msg , error_t err)//3anastelni task an  paketo apetixe 
	{
		//dbg("SRTreeC", "A Routing package sent by NODE_ID=%d...---< %s \n",TOS_NODE_ID,(err==SUCCESS)?"True":"False");
	
		setRoutingSendBusy(FALSE);
		
		if(!(call RoutingSendQueue.empty()))
		{
			post sendRoutingTask();
		}
	
	
		
	}
	
event void CollectionAMSend.sendDone(message_t *msg , error_t err)//3anastelni  task an apetixe paketo 
	{


		//dbg("SRTreeC","AT LEVEL=%d , NODE ID=%d : A Collection package sent... %s !!\n",curdepth,TOS_NODE_ID,(err==SUCCESS)?"True":"False");

		setCollectionSendBusy(FALSE);
		
		if(!(call CollectionSendQueue.empty()))
		{
			post sendCollectionTask();
		}
	
		
		
	}
	


	/////////////ROUTING////////////////
	
	//3ekinA routing kani broadcast minima(id tou , depth tou )

	event void RoutingMsgTimer.fired()
	{
		message_t tmp;
		error_t enqueueDone;
		
		RoutingMsg* mrpkt;
		dbg("SRTreeC", "RoutingMsgTimer fired BY NODE_ID=%d  \n",TOS_NODE_ID);
		
		if(call RoutingSendQueue.full())
		{
			printf("RoutingSendQueue is FULL!!! \n");
			return;
		}
		
		
		mrpkt = (RoutingMsg*) (call RoutingPacket.getPayload(&tmp, sizeof(RoutingMsg)));
		if(mrpkt==NULL)
		{
			dbg("SRTreeC","RoutingMsgTimer.fired(): No valid payload... \n");
			return;
		}

		//vazo sto struct tis metavlites pou 8elo na metafero
		atomic{
		mrpkt->senderID=TOS_NODE_ID;/*to do*/
		mrpkt->depth = curdepth;

		mrpkt->RandChoice = RandChoice;
		mrpkt->FunctionRand= FunctionRand;
		mrpkt->NumOfFunction[0]=NumOfFunction[0];
		mrpkt->NumOfFunction[1]=NumOfFunction[1];


		}
	
		///3ekinao broadcast /stelno dededomena 
		call RoutingAMPacket.setDestination(&tmp, AM_BROADCAST_ADDR);
		call RoutingPacket.setPayloadLength(&tmp, sizeof(RoutingMsg));
		
		enqueueDone=call RoutingSendQueue.enqueue(tmp);
		
		if( enqueueDone==SUCCESS)
		{
			if (call RoutingSendQueue.size()==1)
			{
				post sendRoutingTask();
			}
			
		}
		else
		{
			dbg("SRTreeC","RoutingMsg failed to be enqueued in SendingQueue!!!");

		}		
	}
	
//elexos mexri na gini send
	task void sendRoutingTask()
	{
		
		uint8_t mlen;
		uint16_t mdest;
		error_t sendDone;


		
		if (call RoutingSendQueue.empty())
		{
			dbg("SRTreeC","sendRoutingTask(): Q is empty!\n");
			return;
		}
		
		
		if(RoutingSendBusy)
		{
			dbg("SRTreeC","sendRoutingTask(): RoutingSendBusy= TRUE!!!\n");
			setLostRoutingSendTask(TRUE);
			return;
		}
		
		radioRoutingSendPkt = call RoutingSendQueue.dequeue();
		
		mlen= call RoutingPacket.payloadLength(&radioRoutingSendPkt);
		mdest=call RoutingAMPacket.destination(&radioRoutingSendPkt);
		if(mlen!=sizeof(RoutingMsg))
		{
			dbg("SRTreeC","\t\tsendRoutingTask(): Unknown message!!!\n");
			return;
		}
		sendDone=call RoutingAMSend.send(mdest,&radioRoutingSendPkt,mlen);


		
		if ( sendDone== SUCCESS)
		{
			//dbg("SRTreeC","sendRoutingTask(): Send returned success by NODE_ID=%d!!!\n",TOS_NODE_ID);
			setRoutingSendBusy(TRUE);
		}
		else
		{
			dbg("SRTreeC","send failed!!!\n");
	
		}
	}


//elegxos minimatos 
event message_t* RoutingReceive.receive( message_t * msg , void * payload, uint8_t len)
	{
		error_t enqueueDone;
		message_t tmp;
		uint16_t msource;
		

		msource =call RoutingAMPacket.source(msg);


		//elegxos an den ine i riza 
	if(curdepth == 255 ){	


		atomic{
		memcpy(&tmp,msg,sizeof(message_t));
		}
		enqueueDone=call RoutingReceiveQueue.enqueue(tmp);
		if(enqueueDone == SUCCESS)
		{
			post receiveRoutingTask();
		}
		else
		{
			dbg("SRTreeC","RoutingMsg enqueue failed!!! \n");
	
		}
		
	}
		return msg;
	}


	//Receive minimatos apo komvo/ais8itira 

	task void receiveRoutingTask()
	{
		//message_t tmp;
		uint8_t len;
		message_t radioRoutingRecPkt;

		//error_t enqueueDone;
		RoutingMsg* mrpkt;

		radioRoutingRecPkt= call RoutingReceiveQueue.dequeue();
		
		len= call RoutingPacket.payloadLength(&radioRoutingRecPkt);


		if(len == sizeof(RoutingMsg))
		{
			mrpkt = (RoutingMsg*) (call RoutingPacket.getPayload(&radioRoutingRecPkt,len));	
		
			if ( (parentID<0)||(parentID>=65535))
			{
				// tote den exei akoma patera k tou ana8etoume to sender gia patera me +1 epipedo

				parentID=mrpkt->senderID;
				curdepth= mrpkt->depth + 1;
				RandChoice=	mrpkt->RandChoice ;
				FunctionRand=mrpkt->FunctionRand;
				NumOfFunction[0]=mrpkt->NumOfFunction[0];
				NumOfFunction[1]=mrpkt->NumOfFunction[1];
			
				dbg("SRTreeC" , "NODE_ID=%d is Getting for PARENT the pareintID=%d and  depth= %d \n", TOS_NODE_ID,mrpkt->senderID , mrpkt->depth+1);
				dbg("SRTreeC" , "With RandChoice=%d FunctionRand=%d NumOfFunction[0]=%d NumOfFunction[1]=%d \n",RandChoice,FunctionRand,NumOfFunction[0],NumOfFunction[1]);
					
				//Ke 3ana routing broadcast mexi ola ta pedia na exoun patera

				call RoutingMsgTimer.startOneShot(TIMER_FAST_PERIOD);

			}
			
			}else
			{
				dbg("SRTreeC","receiveRoutingTask():Empty message!!! \n");
				setLostRoutingRecTask(TRUE);
				return;
			}
		
	
}


///////////////////////////////////////////////ROUTING ENDS////////////////////////////////////////////



//////////////Collectionn///////////////
	event void CollectionTimer.fired()
	{
		
		uint8_t measurment;
		uint8_t j;
		message_t tmp;
		error_t enqueueDone;
		msg_with_one_data* mrpkt1;
		msg_with_two_data* mrpkt2;
		msg_with_three_data* mrpkt3;


		//Metrisi ais8itira ke ipologismi 
if(RandChoice==1)
{
					measurment=rand()%(50+1-0)+0;


					count=count+1;
					sum=sum+measurment;
					avg=sum/count;
					if(measurment>max)
					 max=measurment;
					if(measurment<min)
					 min=measurment;

					sumSq=abs(measurment-avg);
						sumSq=sumSq*sumSq;
					var=sumSq/count;


					dbg("SRTreeC", " Collection from NODE_ID=%d at Level-> %d : Num_of_Receives/count=%u Measurment=%u sum=%u avg=%u max=%u min=%d var=%d \n", TOS_NODE_ID,curdepth,count-1,measurment, sum, avg,max,min,var);


					//Elgxos se periptosi pou kapio pedi den apantise na xrisimopioisi proigumeni received  timi
					for(j=0; j<40; j++)
					{
						if (childrenNo[j]!=255)
						{
							if(childrenAnswered[j]==FALSE)
							{
					
								dbg("SRTreeC", " CHILDREN  %d  NOT ANSWERED | FATHER_ID %d \n", childrenNo[j] ,TOS_NODE_ID);


								count=count+childrenReadingCount[j];
								sum=sum+childrenReadingSum[j];
								avg=sum/count;
	
								if(childrenReadingMax[j]>max)
									max=childrenReadingMax[j];
								if(childrenReadingMin[j]<min)
		 							min=childrenReadingMin[j];
			
							}
						else{childrenAnswered[j]=FALSE;}
						}
					}
		

					if (call CollectionSendQueue.full())
					{
						dbg("SRTreeC","CollectionSendQueue is FULL!!\n");
						return;
					}





					if (FunctionRand==1 &&(NumOfFunction[0]<=4))///msg_with_one_data --- min,max,sum,count
					{
		
					collection_length=sizeof(msg_with_one_data);

					mrpkt1=(msg_with_one_data*) (call CollectionPacket.getPayload(&tmp, collection_length));

					atomic{
							mrpkt1->senderID=TOS_NODE_ID;
							mrpkt1->receiverID=parentID;
								if(NumOfFunction[0]==1)	{
									mrpkt1->data1.sum=sum;
								} 
								if(NumOfFunction[0]==2)	 mrpkt1->data1.count=count;
								if(NumOfFunction[0]==3) mrpkt1->data1.max=max;
								if(NumOfFunction[0]==4)	mrpkt1->data1.min=min;

					}	
			
					}//end if
					if (  (FunctionRand==1 && NumOfFunction[0]>4)   || flag==1  )//msg_with_two_data --- avg or var 
					{
					
					collection_length=sizeof(msg_with_two_data);
					mrpkt2=(msg_with_two_data*) (call CollectionPacket.getPayload(&tmp, collection_length));

					
					atomic{
						mrpkt2->senderID=TOS_NODE_ID;
						mrpkt2->receiverID=parentID;
						mrpkt2->data1.sum=sum;	
						mrpkt2->data2.count=count; 
					}
					
					}//end if
					if   (FunctionRand==2 && NumOfFunction[0]<=4 && NumOfFunction[1]<=4  )//msg_with_two_data --- min max sum count sindiasmi 
					{
						
						collection_length=sizeof(msg_with_two_data);
						mrpkt2=(msg_with_two_data*) (call CollectionPacket.getPayload(&tmp, collection_length));

					
						atomic{
						mrpkt2->senderID=TOS_NODE_ID;
						mrpkt2->receiverID=parentID;
						}
					
							switch (NumOfFunction[0]){

							case 1: if(NumOfFunction[1]==2){ atomic{mrpkt2->data1.sum=sum; mrpkt2->data2.count=count;} }//(sum,count)
									if(NumOfFunction[1]==3){ atomic{mrpkt2->data1.sum=sum; mrpkt2->data2.max=max; } }//(sum,max)
									if(NumOfFunction[1]==4){ atomic{mrpkt2->data1.sum=sum; mrpkt2->data2.min=min;} }//(sum,min)
									 break;	
							case 2: if(NumOfFunction[1]==1){ atomic{mrpkt2->data1.count=count; mrpkt2->data2.sum=sum;} }//(count,sum)
									if(NumOfFunction[1]==3){ atomic{mrpkt2->data1.count=count;  mrpkt2->data2.max=max; } }//(count,max)
									if(NumOfFunction[1]==4){ atomic{mrpkt2->data1.count=count;  mrpkt2->data2.min=min;} }//(count,min)
									 break;

							case 3: if(NumOfFunction[1]==1){ atomic{mrpkt2->data1.max=max; mrpkt2->data2.sum=sum;} }//(max,sum)
									if(NumOfFunction[1]==2){ atomic{mrpkt2->data1.max=max; mrpkt2->data2.count=count; } }//(max,count)
									if(NumOfFunction[1]==4){ atomic{mrpkt2->data1.max=max; mrpkt2->data2.min=min;} }//(max,min)
									 break;
							case 4: if(NumOfFunction[1]==1){ atomic{mrpkt2->data1.min=min; mrpkt2->data2.sum=sum;} }//(min,sum)
									if(NumOfFunction[1]==2){ atomic{mrpkt2->data1.min=min; mrpkt2->data2.count=count; } }//(min,count)
									if(NumOfFunction[1]==3){ atomic{mrpkt2->data1.min=min; mrpkt2->data2.max=max;} }//(min,max)
									 break;
							default :break;
							}					
							}//end if
							if (FunctionRand==2 && ( ( NumOfFunction[0]>4 && NumOfFunction[1]<=4 )  ||( NumOfFunction[0]<=4 && NumOfFunction[1]>4 )) )//msg_with_three_data --- ( min or max )and (avg or var)   ----- to (avg,sum) kai (var,sum) .... vlepe flag pio panw
							{
							
							collection_length=sizeof(msg_with_three_data);
							mrpkt3=(msg_with_three_data*) (call CollectionPacket.getPayload(&tmp, collection_length));


							atomic{
								mrpkt3->senderID=TOS_NODE_ID;
								mrpkt3->receiverID=parentID;
							}
					
							if(NumOfFunction[0]==4 || NumOfFunction[1]==4  )//an kapio apo ta dio einai to min
							   { atomic{mrpkt3->data1.min=min; mrpkt3->data2.count=count;  mrpkt3->data3.sum=sum;}} //(min,avg) (min,var)
							
							if(NumOfFunction[0]==3 || NumOfFunction[1]==3  )//an kapio apo ta dio einai to max
							   { atomic{mrpkt3->data1.max=max; mrpkt3->data2.count=count;  mrpkt3->data3.sum=sum;} }//(min,avg) (min,var)
						
						

							}//end if 




	
	
	
								call CollectionAMPacket.setDestination(&tmp, parentID);
								call CollectionPacket.setPayloadLength(&tmp, collection_length);
								enqueueDone=call CollectionSendQueue.enqueue(tmp);

								if(enqueueDone==SUCCESS)
								{
								if(call CollectionSendQueue.size()==1)
								{
									post sendCollectionTask();
								}
			
								}		
								else
								{ 
									dbg("SRTreeC", "CollectionMsg failed to enqueued in SendingQueue");
								}
		
}

if(RandChoice==2)
{
				
				

					measurment=rand()%(50+1-0)+0;
						//count=count+1;

					if (NumOfFunction[0]==1)
					{
						sum=sum+measurment;
						//dbg("SRTreeC", " Old_Value = %d    ||| New_value  = %d \n", sum_old,sum);
						if (sum_old==0)
						sum_old=1;


						if(sum>sum_old)
							comp_tct=(float)(sum- sum_old)/(sum_old)*100;
						else
							comp_tct=(float)(sum_old- sum)/(sum_old)*100;
				

			
					//dbg("SRTreeC", " New_TCT=%f \n", (float)comp_tct);
					if(comp_tct>TCT)
						tct_flag=1;
					else
						tct_flag=0;

								if(TOS_NODE_ID==0 && tct_flag==0)
									sum=sum_old;


							sum_old=sum;
					}

					if (NumOfFunction[0]==2)
					{
					
						count=count+1;
						tct_flag=1;

					}

					if (NumOfFunction[0]==3)
					{
						if(measurment>max)
					 	max=measurment;

					 if (max>max_old)
					 	comp_tct=(float)(max- max_old)/(max_old)*100;
					 else
					 	comp_tct=(float)(max_old- max)/(max_old)*100;


					 if(comp_tct>TCT)
						tct_flag=1;
					else
						tct_flag=0;

							if(TOS_NODE_ID==0 && tct_flag==0)
									max=max_old;
					max_old=max;


					}

					if (NumOfFunction[0]==4)
					{
		
						if(measurment<min)
					 	min=measurment;


					 if (min>min_old)
					 	comp_tct=(float)(min- min_old)/(min_old)*100;
					 else
					 	comp_tct=(float)(min_old- min)/(min_old)*100;


					 if(comp_tct>TCT)
						tct_flag=1;
					else
						tct_flag=0;


							if(TOS_NODE_ID==0 && tct_flag==0)
									min=min_old;
					min_old=min;

					}


					
					
					
											



				///Panta xrisimopoio palia dedomena an den apantisan ta pedia mou  extos ke an ine 1 dld to pedi mou apetixe to tct
				
						for(j=0; j<40; j++)
					{
						if (childrenNo[j]!=255)
						{
							if(childrenAnswered[j]==FALSE )//
							{
								

		 							dbg("SRTreeC", " Children  %d  not awnsered taking old value | Father_Id %d \n", childrenNo[j] ,TOS_NODE_ID);


									count=count+childrenReadingCount[j];
									sum=sum+childrenReadingSum[j];
									
	
									if(childrenReadingMax[j]>max)
										max=childrenReadingMax[j];
									if(childrenReadingMin[j]<min)
		 								min=childrenReadingMin[j];
		 						
			
							}
						else{childrenAnswered[j]=FALSE;}
						}
					}
		
					

				if(tct_flag==1 )
				{

					heartbeat_count=0;//midenizete giati petixe to tct
					heartbeat=0;

				dbg("SRTreeC","New Value over TCT->Sending \n");
					

					if (call CollectionSendQueue.full())
					{
						dbg("SRTreeC","CollectionSendQueue is FULL!!\n");
						return;
					}

					dbg("SRTreeC", " Collection from NODE_ID=%d at Level-> %d : Num_of_Receives/count=%u Measurment=%u sum=%u  max=%u min=%d \n", TOS_NODE_ID,curdepth,count-1,measurment, sum,max,min);
							
									collection_length=sizeof(msg_with_one_data);
									mrpkt1=(msg_with_one_data*) (call CollectionPacket.getPayload(&tmp, collection_length));
									atomic{
											mrpkt1->senderID=TOS_NODE_ID;
											mrpkt1->receiverID=parentID;
											if(NumOfFunction[0]==1)	{mrpkt1->data1.sum=sum;}	
											if(NumOfFunction[0]==2)	 mrpkt1->data1.count=count;
											if(NumOfFunction[0]==3) mrpkt1->data1.max=max;
											if(NumOfFunction[0]==4)	mrpkt1->data1.min=min;
										  }	


								call CollectionAMPacket.setDestination(&tmp, parentID);
								call CollectionPacket.setPayloadLength(&tmp, collection_length);
								enqueueDone=call CollectionSendQueue.enqueue(tmp);

								if(enqueueDone==SUCCESS)
								{
								if(call CollectionSendQueue.size()==1)
								{
									post sendCollectionTask();
								}
			
								}		
								else
								{ 
									dbg("SRTreeC", "CollectionMsg failed to enqueued in SendingQueue");
								}
					}
					if (tct_flag==0)//Apetixe tct den stelno tpt  
					{
						dbg("SRTreeC"," New Value Lower than TCT ->NO SEND\n");

						heartbeat_count++;
						if (heartbeat_count==5)
						{
							heartbeat_count=0;
															
								collection_length=sizeof(msg_with_one_data);
								mrpkt1=(msg_with_one_data*) (call CollectionPacket.getPayload(&tmp, collection_length));
								atomic{
										mrpkt1->senderID=TOS_NODE_ID;
										mrpkt1->receiverID=parentID;
										mrpkt1->data1.heartbeat=2;
									
									  }	
							
							dbg("SRTreeC", "!!!!!!!Sending heartbeat!!!!!! \n");

							
						
						


							if (call CollectionSendQueue.full())
							{
								dbg("SRTreeC","CollectionSendQueue is FULL!!\n");
								return;
							}


							call CollectionAMPacket.setDestination(&tmp, parentID);
								call CollectionPacket.setPayloadLength(&tmp, collection_length);
								enqueueDone=call CollectionSendQueue.enqueue(tmp);

								if(enqueueDone==SUCCESS)
								{
								if(call CollectionSendQueue.size()==1)
								{
									post sendCollectionTask();
								}
			
								}		
								else
								{ 
									dbg("SRTreeC", "CollectionMsg failed to enqueued in SendingQueue");
								}

							}
					}

}





	}//end task




	/**
	 * dequeues a message and sends it
	 */
		task void sendCollectionTask()
	{
		uint8_t mlen;
		error_t sendDone;
		uint16_t mdest;		
		
		

		if (call CollectionSendQueue.empty())
		{
			dbg("SRTreeC","sendCollectionTask(): Q is empty!\n");
			return;
		}
		
		if(CollectionSendBusy==TRUE)
		{
			dbg("SRTreeC","sendCollectionTask(): CollectionSendBusy= TRUE!!!\n");
			setLostCollectionSendTask(TRUE);
			return;
		}
		
		radioCollectionSendPkt = call CollectionSendQueue.dequeue();
		
		mlen=call CollectionPacket.payloadLength(&radioCollectionSendPkt);
		mdest= call CollectionAMPacket.destination(&radioCollectionSendPkt);
		
		if(mlen!=  collection_length)
		{
			dbg("SRTreeC", "\t\t sendCollectionTask(): Unknown message!!\n");
			return;
		}
		sendDone= call CollectionAMSend.send(mdest, &radioCollectionSendPkt,mlen);
		
		if ( sendDone== SUCCESS)
		{
			setCollectionSendBusy(TRUE);
		}
		else
		{
			dbg("SRTreeC","send failed!!!\n");
		}
	}


	
	
	event message_t* CollectionReceive.receive( message_t* msg , void* payload , uint8_t len)
	{
		error_t enqueueDone;
		message_t tmp;
		uint16_t msource;
		
		msource = call CollectionAMPacket.source(msg);
		dbg("SRTreeC", "AT LEVEL = %d NODE_ID = %d  received  from CHILD=%u  \n",curdepth,TOS_NODE_ID,((RoutingMsg*) payload)->senderID);
		

		atomic{
		memcpy(&tmp,msg,sizeof(message_t));
		}
		enqueueDone=call CollectionReceiveQueue.enqueue(tmp);
		
		if( enqueueDone== SUCCESS)
		{

			post receiveCollectionTask();
		}
		else
		{
			dbg("SRTreeC","CollectionMsg enqueue failed!!! \n");	
		}
		
		//call Leds.led1Off();
		//dbg("SRTreeC", "### CollectionReceive.receive() end ##### \n");
		return msg;
	}

	
	/**
	 * dequeues a message and processes it
	 */
	
	task void receiveCollectionTask()
	{
		uint8_t len;
		message_t radioCollectionRecPkt;
		msg_with_one_data* mrpkt1;
		msg_with_two_data* mrpkt2;
		msg_with_three_data* mrpkt3;
		uint8_t temp_len;
		
		radioCollectionRecPkt= call CollectionReceiveQueue.dequeue();

								
if(RandChoice==1){
		if(FunctionRand==1)
			temp_len=sizeof(msg_with_one_data);
		if (  (FunctionRand==1 && NumOfFunction[0]>4)   || flag==1 )
			temp_len=sizeof(msg_with_two_data);
		if   (FunctionRand==2 && NumOfFunction[0]<=4 && NumOfFunction[1]<=4  )//msg_with_two_data --- min max sum count sindiasmi 
				temp_len=sizeof(msg_with_two_data);
		if (FunctionRand==2 && ( NumOfFunction[0]<=4 && NumOfFunction[1]>4 ) )//msg_with_three_data --- ( min or max )and (avg or var)   ----- to (avg,sum) kai (var,sum) .... vlepe flag pio panw
				temp_len=sizeof(msg_with_three_data);
		len= call CollectionPacket.payloadLength(&radioCollectionRecPkt);
			//dbg("SRTreeC", "Im node_id %d collection_length ----------->%d  ||||||| len ------>%d \n", TOS_NODE_ID, collection_length,len);



		if (FunctionRand==1 &&(NumOfFunction[0]<=4))///msg_with_one_data --- min,max,sum,count
		{
				if(len == temp_len)
				{
					mrpkt1 = (msg_with_one_data*) (call CollectionPacket.getPayload(&radioCollectionRecPkt,len));
			
			
				if ( mrpkt1->receiverID == TOS_NODE_ID)//tote to paketo einai gia emas
				{
				//dbg("SRTreeC","PARENTID = %d is receiving measurments from CHILD = %d\n",TOS_NODE_ID,mrpkt->senderID);
				
				//lamvani ta dedomena tou ais8itira
			
				if(NumOfFunction[0]==1) sum=sum+mrpkt1->data1.sum;
				if(NumOfFunction[0]==2)	count=count+mrpkt1->data1.count;
				if(NumOfFunction[0]==3) {  if(mrpkt1->data1.max > max)  max=mrpkt1->data1.max;}
				if(NumOfFunction[0]==4)	{ if(mrpkt1->data1.min < min) min=mrpkt1->data1.min;}
			

				//KA8e fora pou enas komvos lamvani apo ta pedia tou ananeoni ke tis plirofories pou ixe gia auta 				
				if (childrenNo[mrpkt1->senderID]==mrpkt1->senderID)
				{
					if(NumOfFunction[0]==1)	 childrenReadingSum[mrpkt1->senderID]=mrpkt1->data1.sum;
					if(NumOfFunction[0]==2) childrenReadingCount[mrpkt1->senderID]=mrpkt1->data1.count;
					if(NumOfFunction[0]==3) childrenReadingMax[mrpkt1->senderID]=mrpkt1->data1.max;
					if(NumOfFunction[0]==4) childrenReadingMin[mrpkt1->senderID]=mrpkt1->data1.min;
					childrenAnswered[mrpkt1->senderID]=TRUE;
				}

				//Ginete mono sto proto collection etsi oste o ka8e komvos na 3eri ta pedia tou 	
				if (my_parent_recognised_me[mrpkt1->senderID]==FALSE)
				{
				
				my_parent_recognised_me[mrpkt1->senderID]=TRUE;
				//childrenNo[mrpkt->senderID]=mrpkt->senderID;
				if(NumOfFunction[0]==1) childrenReadingSum[mrpkt1->senderID]=mrpkt1->data1.sum;
				if(NumOfFunction[0]==2)childrenReadingCount[mrpkt1->senderID]=mrpkt1->data1.count;
				if(NumOfFunction[0]==3) childrenReadingMax[mrpkt1->senderID]=mrpkt1->data1.max;
				if(NumOfFunction[0]==4) childrenReadingMin[mrpkt1->senderID]=mrpkt1->data1.min;
				//childrenReadingCount[mrpkt->senderID]=mrpkt->count;
				childrenAnswered[mrpkt1->senderID]=TRUE;
				}
				


				}
				}
		}
		if (  (FunctionRand==1 && NumOfFunction[0]>4)    || flag==1 )
		{

				if(len == temp_len)
				{
					mrpkt2 = (msg_with_two_data*) (call CollectionPacket.getPayload(&radioCollectionRecPkt,len));
			
			
				if ( mrpkt2->receiverID == TOS_NODE_ID)//tote to paketo einai gia emas
				{
				//dbg("SRTreeC","PARENTID = %d is receiving measurments from CHILD = %d\n",TOS_NODE_ID,mrpkt->senderID);
				
				//lamvani ta dedomena tou ais8itira
			
					sum=sum+mrpkt2->data1.sum;
					count=count+mrpkt2->data2.count;
				
			

				//KA8e fora pou enas komvos lamvani apo ta pedia tou ananeoni ke tis plirofories pou ixe gia auta 				
				
						//KA8e fora pou enas komvos lamvani apo ta pedia tou ananeoni ke tis plirofories pou ixe gia auta 				
						if (childrenNo[mrpkt2->senderID]==mrpkt2->senderID)
						{
								childrenReadingSum[mrpkt2->senderID]=mrpkt2->data1.sum;
								childrenReadingCount[mrpkt2->senderID]=mrpkt2->data2.count;
								childrenAnswered[mrpkt2->senderID]=TRUE;
						}
				
						//Ginete mono sto proto collection etsi oste o ka8e komvos na 3eri ta pedia tou 	
						if (my_parent_recognised_me[mrpkt2->senderID]==FALSE)
						{
								my_parent_recognised_me[mrpkt2->senderID]=TRUE;
								childrenNo[mrpkt2->senderID]=mrpkt2->senderID;
								childrenReadingSum[mrpkt2->senderID]=mrpkt2->data1.sum;
								childrenReadingCount[mrpkt2->senderID]=mrpkt2->data2.count;
								childrenAnswered[mrpkt2->senderID]=TRUE;
						}
				


				}
				}
		}
		if   (FunctionRand==2 && NumOfFunction[0]<=4 && NumOfFunction[1]<=4  )//msg_with_two_data --- min max sum count sindiasmi 
		{
		
						mrpkt2=(msg_with_two_data*) (call CollectionPacket.getPayload(&radioCollectionRecPkt,len));

						if ( mrpkt2->receiverID == TOS_NODE_ID)//tote to paketo einai gia emas
						{
						
								//dbg("SRTreeC","PARENTID = %d is receiving measurments from CHILD = %d\n",TOS_NODE_ID,mrpkt->senderID);
					
								//lamvani ta dedomena tou ais8itira
								switch (NumOfFunction[0]){

								case 1: if(NumOfFunction[1]==2){ atomic{sum=sum+mrpkt2->data1.sum; count=count+mrpkt2->data2.count;} }//(sum,count)
										if(NumOfFunction[1]==3){ atomic{sum=sum+mrpkt2->data1.sum;  if(mrpkt2->data2.max > max)  max=mrpkt2->data2.max; } }//(sum,max)
										if(NumOfFunction[1]==4){ atomic{sum=sum+mrpkt2->data1.sum;   if(mrpkt2->data2.min <min)  {min=mrpkt2->data2.min;}} }//(sum,min)
										 break;	
								case 2: if(NumOfFunction[1]==1){ atomic{count=count+mrpkt2->data1.count; sum=sum+mrpkt2->data2.sum;} }//(count,sum)
										if(NumOfFunction[1]==3){ atomic{count=count+mrpkt2->data1.count; if(mrpkt2->data2.max > max)  max=mrpkt2->data2.max; } }//(count,max)
										if(NumOfFunction[1]==4){ atomic{count=count+mrpkt2->data1.count;  if(mrpkt2->data2.min < min)  {min=mrpkt2->data2.min;}} }//(count,min)
										 break;

								case 3: if(NumOfFunction[1]==1){ atomic{ if(mrpkt2->data1.max > max) { max=mrpkt2->data1.max;} sum=sum+mrpkt2->data2.sum;} }//(max,sum)
										if(NumOfFunction[1]==2){ atomic{ if(mrpkt2->data1.max > max) { max=mrpkt2->data1.max;} count=count+mrpkt2->data2.count; } }//(max,count)
										if(NumOfFunction[1]==4){ atomic{ if(mrpkt2->data1.max > max) { max=mrpkt2->data1.max;}  if(mrpkt2->data2.min < min)  {min=mrpkt2->data2.min;}} }//(max,min)
										 break;
								case 4: if(NumOfFunction[1]==1){ atomic{ if(mrpkt2->data1.min < min)  {min=mrpkt2->data1.min;} sum=sum+mrpkt2->data2.sum;} }//(min,sum)
										if(NumOfFunction[1]==2){ atomic{ if(mrpkt2->data1.min < min)  {min=mrpkt2->data1.min;} count=count+mrpkt2->data2.count; } }//(min,count)
										if(NumOfFunction[1]==3){ atomic{ if(mrpkt2->data1.min < min)  {min=mrpkt2->data1.min;}  if(mrpkt2->data2.max > max)  max=mrpkt2->data2.max;} }//(min,max)
										 break;
								default :break;
								}

								//KA8e fora pou enas komvos lamvani apo ta pedia tou ananeoni ke tis plirofories pou ixe gia auta 				
								if (childrenNo[mrpkt2->senderID]==mrpkt2->senderID)
								{
								
								switch (NumOfFunction[0]){

								case 1: if(NumOfFunction[1]==2){ atomic{childrenReadingSum[mrpkt2->senderID]=mrpkt2->data1.sum;  childrenReadingCount[mrpkt2->senderID]=mrpkt2->data2.count;} }//(sum,count)
									if(NumOfFunction[1]==3){ atomic{childrenReadingSum[mrpkt2->senderID]=mrpkt2->data1.sum;  childrenReadingMax[mrpkt2->senderID]=mrpkt2->data2.max; } }//(sum,max)
									if(NumOfFunction[1]==4){ atomic{childrenReadingSum[mrpkt2->senderID]=mrpkt2->data1.sum;  childrenReadingMin[mrpkt2->senderID]=mrpkt2->data2.min;} }//(sum,min)
									 break;	
								case 2: if(NumOfFunction[1]==1){ atomic{childrenReadingCount[mrpkt2->senderID]=mrpkt2->data1.count; childrenReadingSum[mrpkt2->senderID]=mrpkt2->data2.sum;} }//(count,sum)
									if(NumOfFunction[1]==3){ atomic{childrenReadingCount[mrpkt2->senderID]=mrpkt2->data1.count;  childrenReadingMax[mrpkt2->senderID]=mrpkt2->data2.max; } }//(count,max)
									if(NumOfFunction[1]==4){ atomic{childrenReadingCount[mrpkt2->senderID]=mrpkt2->data1.count;  childrenReadingMin[mrpkt2->senderID]=mrpkt2->data2.min;} }//(count,min)
									 break;

								case 3: if(NumOfFunction[1]==1){ atomic{childrenReadingMax[mrpkt2->senderID]=mrpkt2->data1.max; childrenReadingSum[mrpkt2->senderID]=mrpkt2->data2.sum;} }//(max,sum)
									if(NumOfFunction[1]==2){ atomic{childrenReadingMax[mrpkt2->senderID]=mrpkt2->data1.max; childrenReadingCount[mrpkt2->senderID]=mrpkt2->data2.count; } }//(max,count)
									if(NumOfFunction[1]==4){ atomic{childrenReadingMax[mrpkt2->senderID]=mrpkt2->data1.max;  childrenReadingMin[mrpkt2->senderID]=mrpkt2->data2.min;} }//(max,min)
									 break;
								case 4: if(NumOfFunction[1]==1){ atomic{childrenReadingMin[mrpkt2->senderID]=mrpkt2->data1.min; childrenReadingSum[mrpkt2->senderID]=mrpkt2->data2.sum;} }//(min,sum)
									if(NumOfFunction[1]==2){ atomic{childrenReadingMin[mrpkt2->senderID]=mrpkt2->data1.min; childrenReadingCount[mrpkt2->senderID]=mrpkt2->data2.count; } }//(min,count)
									if(NumOfFunction[1]==3){ atomic{childrenReadingMin[mrpkt2->senderID]=mrpkt2->data1.min;  childrenReadingMax[mrpkt2->senderID]=mrpkt2->data2.max;} }//(min,max)
									 break;
								default :break;


								}
								childrenAnswered[mrpkt2->senderID]=TRUE;


								}
				
								//Ginete mono sto proto collection etsi oste o ka8e komvos na 3eri ta pedia tou 	
								if (my_parent_recognised_me[mrpkt2->senderID]==FALSE)
								{

								my_parent_recognised_me[mrpkt2->senderID]=TRUE;
								childrenNo[mrpkt2->senderID]=mrpkt2->senderID;
									switch (NumOfFunction[0]){

								case 1: if(NumOfFunction[1]==2){ atomic{childrenReadingSum[mrpkt2->senderID]=mrpkt2->data1.sum;  childrenReadingCount[mrpkt2->senderID]=mrpkt2->data2.count;} }//(sum,count)
									if(NumOfFunction[1]==3){ atomic{childrenReadingSum[mrpkt2->senderID]=mrpkt2->data1.sum;  childrenReadingMax[mrpkt2->senderID]=mrpkt2->data2.max; } }//(sum,max)
									if(NumOfFunction[1]==4){ atomic{childrenReadingSum[mrpkt2->senderID]=mrpkt2->data1.sum;  childrenReadingMin[mrpkt2->senderID]=mrpkt2->data2.min;} }//(sum,min)
									 break;	
								case 2: if(NumOfFunction[1]==1){ atomic{childrenReadingCount[mrpkt2->senderID]=mrpkt2->data1.count; childrenReadingSum[mrpkt2->senderID]=mrpkt2->data2.sum;} }//(count,sum)
									if(NumOfFunction[1]==3){ atomic{childrenReadingCount[mrpkt2->senderID]=mrpkt2->data1.count;  childrenReadingMax[mrpkt2->senderID]=mrpkt2->data2.max; } }//(count,max)
									if(NumOfFunction[1]==4){ atomic{childrenReadingCount[mrpkt2->senderID]=mrpkt2->data1.count;  childrenReadingMin[mrpkt2->senderID]=mrpkt2->data2.min;} }//(count,min)
									 break;

								case 3: if(NumOfFunction[1]==1){ atomic{childrenReadingMax[mrpkt2->senderID]=mrpkt2->data1.max; childrenReadingSum[mrpkt2->senderID]=mrpkt2->data2.sum;} }//(max,sum)
									if(NumOfFunction[1]==2){ atomic{childrenReadingMax[mrpkt2->senderID]=mrpkt2->data1.max; childrenReadingCount[mrpkt2->senderID]=mrpkt2->data2.count; } }//(max,count)
									if(NumOfFunction[1]==4){ atomic{childrenReadingMax[mrpkt2->senderID]=mrpkt2->data1.max;  childrenReadingMin[mrpkt2->senderID]=mrpkt2->data2.min;} }//(max,min)
									 break;
								case 4: if(NumOfFunction[1]==1){ atomic{childrenReadingMin[mrpkt2->senderID]=mrpkt2->data1.min; childrenReadingSum[mrpkt2->senderID]=mrpkt2->data2.sum;} }//(min,sum)
									if(NumOfFunction[1]==2){ atomic{childrenReadingMin[mrpkt2->senderID]=mrpkt2->data1.min; childrenReadingCount[mrpkt2->senderID]=mrpkt2->data2.count; } }//(min,count)
									if(NumOfFunction[1]==3){ atomic{childrenReadingMin[mrpkt2->senderID]=mrpkt2->data1.min;  childrenReadingMax[mrpkt2->senderID]=mrpkt2->data2.max;} }//(min,max)
									 break;
								default :break;
								}
								childrenAnswered[mrpkt2->senderID]=TRUE;
								}
				
								} //endif ( mrpkt->receiverID == TOS_NODE_ID)
		
		}//end if
						if (FunctionRand==2 && ( ( NumOfFunction[0]>4 && NumOfFunction[1]<=4 )  ||( NumOfFunction[0]<=4 && NumOfFunction[1]>4 )) )//msg_with_three_data --- ( min or max )and (avg or var)   ----- to (avg,sum) kai (var,sum) .... vlepe flag pio panw
						{
							
							mrpkt3=(msg_with_three_data*) (call CollectionPacket.getPayload(&radioCollectionRecPkt,len));

							if ( mrpkt3->receiverID == TOS_NODE_ID)//tote to paketo einai gia emas
							{
							//dbg("SRTreeC","PARENTID = %d is receiving measurments from CHILD = %d\n",TOS_NODE_ID,mrpkt->senderID);
					
							//lamvani ta dedomena tou ais8itira

					 
							if(NumOfFunction[0]==4 || NumOfFunction[1]==4  )//an kapio apo ta dio einai to min
							   { atomic{if(mrpkt3->data1.min < min)  {min=mrpkt3->data1.min;} count=count+mrpkt3->data2.count;  sum=sum+mrpkt3->data3.sum;}} //(min,avg) (min,var)
							
							if(NumOfFunction[0]==3 || NumOfFunction[1]==3  )//an kapio apo ta dio einai to max
							   { atomic{if(mrpkt3->data1.max > max)  {max=mrpkt3->data1.max;} count=count+mrpkt3->data2.count;  sum=sum+mrpkt3->data3.sum;} }//(max,avg) (max,var)
					

							//KA8e fora pou enas komvos lamvani apo ta pedia tou ananeoni ke tis plirofories pou ixe gia auta 				
							if (childrenNo[mrpkt3->senderID]==mrpkt3->senderID)
							{

								if(NumOfFunction[0]==4 || NumOfFunction[1]==4  )//an kapio apo ta dio einai to min
							   	{ atomic{ childrenReadingMin[mrpkt3->senderID]=mrpkt3->data1.min;
							   			  childrenReadingCount[mrpkt3->senderID]=mrpkt3->data2.count; 
							   			  sum=mrpkt3->data3.sum;}
							   	} //(min,avg) (min,var)
							
								if(NumOfFunction[0]==3 || NumOfFunction[1]==3  )//an kapio apo ta dio einai to max
							   { atomic{ childrenReadingMax[mrpkt3->senderID]=mrpkt3->data1.max;
							   			  childrenReadingCount[mrpkt3->senderID]=mrpkt3->data2.count; 
							   			  sum=mrpkt3->data3.sum;}
							   	} //(max,avg) (max,var)

					
							   		childrenAnswered[mrpkt3->senderID]=TRUE;
							}
				
							//Ginete mono sto proto collection etsi oste o ka8e komvos na 3eri ta pedia tou 	
							if (my_parent_recognised_me[mrpkt3->senderID]==FALSE)
							{

								my_parent_recognised_me[mrpkt3->senderID]=TRUE;
								childrenNo[mrpkt3->senderID]=mrpkt3->senderID;
								if(NumOfFunction[0]==4 || NumOfFunction[1]==4  )//an kapio apo ta dio einai to min
							   	{ atomic{ childrenReadingMin[mrpkt3->senderID]=mrpkt3->data1.min;
							   			  childrenReadingCount[mrpkt3->senderID]=mrpkt3->data2.count; 
							   			  sum=mrpkt3->data3.sum;}
							   	} //(min,avg) (min,var)
							
								if(NumOfFunction[0]==3 || NumOfFunction[1]==3  )//an kapio apo ta dio einai to max
							   	{ atomic{ childrenReadingMax[mrpkt3->senderID]=mrpkt3->data1.max;
							   			  childrenReadingCount[mrpkt3->senderID]=mrpkt3->data2.count; 
							   			  sum=mrpkt3->data3.sum;}
							   	} //(max,avg) (max,var)
								childrenAnswered[mrpkt3->senderID]=TRUE;
							}
				
							}//endif ( mrpkt->receiverID == TOS_NODE_ID)
						
		}//end if 
}
								

if(RandChoice==2)
		{
						temp_len=sizeof(msg_with_one_data);
						len= call CollectionPacket.payloadLength(&radioCollectionRecPkt);

						if (NumOfFunction[0]<=4)///msg_with_one_data --- min,max,sum,count
						{
								
							if(len == temp_len)
							{
									
								mrpkt1 = (msg_with_one_data*) (call CollectionPacket.getPayload(&radioCollectionRecPkt,len));
			
								if ( mrpkt1->receiverID == TOS_NODE_ID)//tote to paketo einai gia emas
								{
										//dbg("SRTreeC", " NODE  %d and my count is %d || HEARTBEAT = %d \n",TOS_NODE_ID,count, mrpkt1->data1.heartbeat);
													//lamvani ta dedomena tou ais8itira
										if ( mrpkt1->data1.heartbeat!=2 )//an to minima exi dedomena dld den ine notify i heartbeat 
									{
											//dbg("SRTreeC", " INSIDE HEARTBEAT \n");
										if(NumOfFunction[0]==1) sum=sum+mrpkt1->data1.sum;
										if(NumOfFunction[0]==2)	{count=count+mrpkt1->data1.count; }
										if(NumOfFunction[0]==3) {  if(mrpkt1->data1.max > max)  max=mrpkt1->data1.max;}
										if(NumOfFunction[0]==4)	{ if(mrpkt1->data1.min < min) min=mrpkt1->data1.min;}
			

										//KA8e fora pou enas komvos lamvani apo ta pedia tou ananeoni ke tis plirofories pou ixe gia auta 				
										if (childrenNo[mrpkt1->senderID]==mrpkt1->senderID)
										{
											childrenHeartbeat[mrpkt1->senderID]=mrpkt1->data1.heartbeat;

											if(NumOfFunction[0]==1)	 childrenReadingSum[mrpkt1->senderID]=mrpkt1->data1.sum;
											if(NumOfFunction[0]==2) childrenReadingCount[mrpkt1->senderID]=mrpkt1->data1.count;
											if(NumOfFunction[0]==3) childrenReadingMax[mrpkt1->senderID]=mrpkt1->data1.max;
											if(NumOfFunction[0]==4) childrenReadingMin[mrpkt1->senderID]=mrpkt1->data1.min;
											childrenAnswered[mrpkt1->senderID]=TRUE;
										}

										//Ginete mono sto proto collection etsi oste o ka8e komvos na 3eri ta pedia tou 	
										if (my_parent_recognised_me[mrpkt1->senderID]==FALSE)
										{
				
											my_parent_recognised_me[mrpkt1->senderID]=TRUE;
											childrenNo[mrpkt1->senderID]=mrpkt1->senderID;
											if(NumOfFunction[0]==1) childrenReadingSum[mrpkt1->senderID]=mrpkt1->data1.sum;
											if(NumOfFunction[0]==2)childrenReadingCount[mrpkt1->senderID]=mrpkt1->data1.count;
											if(NumOfFunction[0]==3) childrenReadingMax[mrpkt1->senderID]=mrpkt1->data1.max;
											if(NumOfFunction[0]==4) childrenReadingMin[mrpkt1->senderID]=mrpkt1->data1.min;
											//childrenReadingCount[mrpkt->senderID]=mrpkt->count;
											childrenAnswered[mrpkt1->senderID]=TRUE;
										}
									}
									 else
									{
									

										

										if (childrenNo[mrpkt1->senderID]==mrpkt1->senderID){
											dbg("SRTreeC", "!!! Received Heartbeat FROM CHILDREN  %d  !!!\n",mrpkt1->senderID );

											childrenHeartbeat[mrpkt1->senderID]=mrpkt1->data1.heartbeat;

											childrenAnswered[mrpkt1->senderID]=TRUE;					//to pedi apantise apla den ixe plirofories xrisimes
										}

									}
							
								
				
								}
							}
						}

			}







	}
}	

//////////////////////////////END COLLECTION/////////////////////

