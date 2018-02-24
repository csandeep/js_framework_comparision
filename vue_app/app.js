Vue.component('post-item', {
    props: ['post'],
    template: `<div class="row" v-if="post.id == -1" ><button>Load More</button></div>
    <div :post=post class="row" v-else>
    <div class="row">
    <div class="col s12 m7">
      <div class="card">
        <div class="card-content">
          <p>{{post.title}}</p>
        </div>

      </div>
    </div>
  </div>
    </div>`

});

var app = new Vue({
    el: '#app',
    data: {
        posts: [
            {
                'id': -1,
                'title': 'Load More'
            }
        ],
        page: 1
    },
    mounted: function () {
        this.loadMore();
    },
    methods:  {
        loadMore: function (){
            var that = this;

            fetch("http://localhost:3000/posts/?_limit=8&_page=" + this.page).then(function (response) {
                return response.json();
            }).then( function(data){
                var button = that.posts.pop();
                data.forEach(element => {
                    that.posts.push(element);
                });
    
                that.posts.push(button);
                that.page += 1;
            });
        },
        itemClicked: function(item){
            if( item.id === -1 ){
                this.loadMore();
            }else{

            }
        }
    }
});