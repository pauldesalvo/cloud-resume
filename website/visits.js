function getLoadCount(){
  var req = new XMLHttpRequest();
  req.open('GET', 'API Gateway URL', false);
  req.send();
  if(req.status == 200){
    len = req.responseText.length;
    console.log(req.responseText.substring(1, len-1));
    document.getElementById("loadcount").textContent = req.responseText.substring(10, len-2);
  }
  else {
    //Not 200 HTTP code
    console.log(req.status)
  }
}
window.onload = function(){
  getLoadCount();
};

