BEGIN {
 tcp_droped = 0;
 udp_droped = 0;
 last_tcp = -1;
 last_udp = -1;
 total_tcp = 0;
 total_udp = 0;
 i = 0;
}

{
 action = $1;
 time = $2;
 type = $5;
 seq_no = $11;

 if(action == "+" && type == "tcp"){
  total_tcp = total_tcp + 1;
 }

 if(action == "+" && type == "cbr"){
  total_udp = total_udp + 1;
 }

 if(action=="r"){
  if(type=="tcp"){
   if(seq_no != last_tcp + 1){
    tcp_droped = tcp_droped + 1;
   }
   last_tcp = seq_no;
  }

  if(type=="cbr"){
   if(seq_no != last_udp + 1){
    udp_droped = udp_droped + 1;
   }
   last_udp = seq_no;
  }

  time_point[i] = time;
  if(total_tcp > 0)
   tcp_loss[i] = tcp_droped / total_tcp * 100;
  else
   tcp_loss[i] = 0;
  if(total_udp > 0)
   udp_loss[i] = udp_droped / total_udp * 100;
  else
   udp_loss[i] = 0;
  i = i + 1;
  
 }
 
}

END {
 printf("%.2f\t%.2f\t%.2f\n",0,0,0);

 for(j=0; j<i; j++){
  printf("%.2f\t%.2f\t%.2f\n",time_point[j], tcp_loss[j], udp_loss[j]);
 }
}
