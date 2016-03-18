console.log("ThreadList");

$(".message-item").on("click", function () {    
    var id = $(this).data("id");
    gm(id);
});

function gm(threadid) {
    window.location.href = "Thread" + threadid + ".wwt";
}