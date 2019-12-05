#include <stdio.h>
#include <stdlib.h>
#include <string.h>



int main() {
	int D,j,i,k,count;
	int r;
	int thisPosY,thisPosX,startPosX ,startPosY,endPosX,endPosY,rowNum,colNum;
	float e= -50;
	 //count=0
	FILE *fp;
	do{
	printf("Give grid diameter:");
	scanf("%d", &D);
	} while(D<0 || D>8);
	do{
	printf("Give node range:");
	scanf("%d", &r);
	} while(r<0 || r>4);//gia na perioriso ta paidia pou mpori na exi ka8e komvos 

	int grid[2*D][2*D];
	for (j=0; j<((D*D)); j++){
		grid[j/D][j%D]=j;
	}
	
	
	for(i=0; i<D; i++){
		for(j=0; j<D; j++)
		{
			printf(" %d ", grid[i][j]);
		}
		printf("\n");
	}

	fp=fopen("topology.txt","w");

for ( thisPosX = 0; thisPosX < D; thisPosX++)
{
	for ( thisPosY = 0; thisPosY < D; thisPosY++)
	{
		//for ( k = 1; k <=r; k++){
		
			// See how many are alive
		/*	startPosX = (thisPosX - 1 < 0) ? thisPosX : thisPosX-r;
			startPosY = (thisPosY - 1 < 0) ? thisPosY : thisPosY-r;
 			endPosX =   (thisPosX + 1 > D-1) ? thisPosX : thisPosX+r;
 			endPosY =   (thisPosY + 1 > D-1) ? thisPosY : thisPosY+r;
		*/
 			startPosX = (thisPosX - r > 0) ? thisPosX-r : 0;
			startPosY = (thisPosY - r > 0) ? thisPosY-r : 0;
 			endPosX =   (thisPosX + r < D-1) ? thisPosX+r : D-1;
 			endPosY =   (thisPosY + r < D-1) ? thisPosY+r : D-1;
			for ( rowNum=startPosX; rowNum<=endPosX; rowNum++) 
			{
    			for ( colNum=startPosY; colNum<=endPosY; colNum++) 
    			{
        		// All the neighbors will be grid[rowNum][colNum]
       			// if (grid[rowNum][colNum]>0 && grid[rowNum][colNum]<=D*D)
					if (grid[thisPosX][thisPosY]!=grid[rowNum][colNum] && grid[rowNum][colNum]<D*D && grid[rowNum][colNum]>=0)// && (thisPosX!=rowNum ||thisPosY!=colNum ) )
					{
						
						fprintf(fp,"%d %d %f\n ", grid[thisPosX][thisPosY] , grid[rowNum][colNum], e);

					}
					
    			}
			}
		//}
	}
}


}


/*

	for (int i = 0; i < D; i++)//row
	{
		for (int j = 0; j < D; j++)//colum
		{
			for (int k = -1; k <= 1; k++)//i+(r*2)
			{
				for (int p = -1; p <=1 ; p++)//j+(r*2)
				{
					if (grid[i+k][j+p]>0 && grid[i+k][j+p]<=D*D)
					{
						printf("%d %d %f\n ", grid[i][j] , grid[i+k][j+p], e);
					}
				}
			}
		}
	}

	*/











/*
	for(i=0; i<D; i++){
		for(j=0; j<D; j++)
		{
			for (k=0; k<r; k++){
			 	grid[i-k][j]>=0 ? printf("%d %d %f\n ", grid[i][j] , grid[i-k][j], e) :printf("");
			 	grid[i-k][j+k]>=0 ? printf("%d %d %f\n ", grid[i][j] ,grid[i-k][j+k], e):printf("");
			 	grid[i-k][j-k]>=0 ? printf("%d %d %f\n ", grid[i][j] , grid[i-k][j-k], e):printf("");
			 	grid[i+k][j]>=0 ? printf("%d %d %f\n ", grid[i][j] , grid[i+k][j], e):printf("");
			 	grid[i][j+k]>=0 ? printf("%d %d %f\n ", grid[i][j] , grid[i][j+k], e):printf("");
			 	grid[i+k][j+k]>=0 ? printf("%d %d %f\n ", grid[i][j] , grid[i+k][j+k], e):printf("");
			 	grid[i+k][j-k]>=0 ? printf("%d %d %f\n ", grid[i][j] , grid[i+k][j-k], e):printf("");
			 	grid[i][j-k]>=0 ? printf("%d %d %f\n ", grid[i][j] , grid[i][j-k], e):printf("");

			}
		}
	}
*/
/*
for(i=0; i<D; i++){
		for(j=0; j<D; j++)
		{
			for (k=1; k<=r; k++){




			 	grid[i-k][j]<=64&&grid[i-k][j]>0 ? printf("%d %d %f\n ", grid[i][j] , grid[i-k][j], e) :printf("");
			 	grid[i-k][j+k]<=64&&grid[i-k][j+k]>0 ? printf("%d %d %f\n ", grid[i][j] ,grid[i-k][j+k], e):printf("");
			 	grid[i-k][j-k]<=64&&grid[i-k][j-k]>0 ? printf("%d %d %f\n ", grid[i][j] , grid[i-k][j-k], e):printf("");
			 	grid[i+k][j]<=64&&grid[i+k][j]>0 ? printf("%d %d %f\n ", grid[i][j] , grid[i+k][j], e):printf("");
			 	grid[i][j+k]<=64&&grid[i][j+k]>0 ? printf("%d %d %f\n ", grid[i][j] , grid[i][j+k], e):printf("");
			 	grid[i+k][j+k]<=64&&grid[i+k][j+k]>0 ? printf("%d %d %f\n ", grid[i][j] , grid[i+k][j+k], e):printf("");
			 	grid[i+k][j-k]<=64&&grid[i+k][j-k]>0 ? printf("%d %d %f\n ", grid[i][j] , grid[i+k][j-k], e):printf("");
			 	grid[i][j-k]<=64&&grid[i][j-k]>0 ? printf("%d %d %f\n ", grid[i][j] , grid[i][j-k], e):printf("");

			}
		}
	}

*/



/*


	fp=fopen("topology3.txt","w");
	if (r>=1 && r<2)
{		for(i=0; i<D; i++){
			for(j=0; j<D; j++){
				if( j+r<D && i+r<D){
					fprintf(fp,"%d %d   %f\n", grid[i][j], grid[i+1][j+1], e);
				}
				if( j+r<D ){
					fprintf(fp,"%d %d   %f\n", grid[i][j], grid[i][j+1], e);
				}
				if(i+r<D){
					fprintf(fp,"%d %d   %f\n", grid[i][j], grid[i+1][j], e);
				}
				
				if(i-r>=0 && j-r>=0 ){
					fprintf(fp,"%d %d   %f\n", grid[i][j], grid[i-1][j-1], e);	
				}
				if(i-r>=0 ){
					fprintf(fp,"%d %d   %f\n", grid[i][j], grid[i-1][j], e);
				}
				if(j-r>=0 ){
					fprintf(fp,"%d %d   %f\n", grid[i][j], grid[i][j-1], e);
				}
				if(i-r>=0 && j+r<D){
					fprintf(fp,"%d %d   %f\n", grid[i][j], grid[i-1][j+1], e);
				}
				if(j-r>=0 && i+r<D){
					fprintf(fp,"%d %d   %f\n", grid[i][j], grid[i+1][j-1], e);
				}
			}
		}
	}
	
*/



/*for(i=0; i<D; i++){
			for(j=0; j<D; j++){
				for (int k = 1; k <= r; ++k)
				{
				
				if( j+k<D && i+k<D){
					fprintf(fp,"%d %d   %f\n", grid[i][j], grid[i+k][j+k], e);
					if (k>1){
						fprintf(fp,"%d %d   %f\n", grid[i][j], grid[i+k][j+(k-1)], e);  //+(k-1)
						fprintf(fp,"%d %d   %f\n", grid[i][j], grid[i+(k-1)][j+k], e);
					
					}
					
				}
				if( j+k<D ){
					fprintf(fp,"%d %d   %f\n", grid[i][j], grid[i][j+k], e);
				}
				if(i+k<D){
					fprintf(fp,"%d %d   %f\n", grid[i][j], grid[i+k][j], e);
				}
				
				if(i-k>=0 && j-k>=0 ){
					fprintf(fp,"%d %d   %f\n", grid[i][j], grid[i-k][j-k], e);	
					if(k>1){
					fprintf(fp,"%d %d   %f\n", grid[i][j], grid[i-k][j-(k-1)], e);
					fprintf(fp,"%d %d   %f\n", grid[i][j], grid[i-(k-1)][j-k], e);
					}
				}
				if(i-k>=0 ){
					fprintf(fp,"%d %d   %f\n", grid[i][j], grid[i-k][j], e);
				}
				if(j-k>=0 ){
					fprintf(fp,"%d %d   %f\n", grid[i][j], grid[i][j-k], e);
				}
				if(i-k>=0 && j+k<D){
					fprintf(fp,"%d %d   %f\n", grid[i][j], grid[i-k][j+k], e);
					if(k>1){
					fprintf(fp,"%d %d   %f\n", grid[i][j], grid[i-k][j+(k-1)], e);
					fprintf(fp,"%d %d   %f\n", grid[i][j], grid[i-(k-1)][j+k], e);
					}
				}
				if(j-k>=0 && i+k<D){
					fprintf(fp,"%d %d   %f\n", grid[i][j], grid[i+k][j-k], e);
					if (k>1){
					fprintf(fp,"%d %d   %f\n", grid[i][j], grid[i+k][j-(k-1)], e);
					fprintf(fp,"%d %d   %f\n", grid[i][j], grid[i+(k-1)][j-k], e);
						}

				}


				*/
