import React, {Component} from "react";
import update from 'immutability-helper';

class Posts extends Component {
    constructor() {
        super();
        this.state = {
            page: 1,
            posts: [
                {
                    id: -1
                }
            ],
            isInfiniteLoading: true
        };
    }

    componentDidMount() {
        this.fetchPosts(this.state.page);
    }

    fetchPosts() {
        var newState = update(this.state, {
            isInfiniteLoading: {
                $set: true
            }
        });
        this.setState(newState);
        var component = this;

        fetch("http://localhost:3000/posts/?_limit=8&_page=" + this.state.page).then(function (response) {
            return response.json();
        })
            .then(function (data) {

                if (data.length > 0) {
                    // add load more to the end of the list
                    data.push({id: -1});
                }

                // remove load more button
                component.setState({
                    posts: component
                        .state
                        .posts
                        .slice(0, -1)
                });

                var newState = update(component.state, {
                    posts: {
                        $push: data
                    },
                    page: {
                        $set: component.state.page + 1
                    },
                    isInfiniteLoading: {
                        $set: true
                    }
                });

                component.setState(newState);
            });
    }

    openPost(post) {
        window.location = post.link;
    }

    createPostRow(item) {
        if (item.id === -1) {

            return <button
                class="waves-effect waves-light btn"
                href="#"
                onClick={() => this.fetchPosts()}>Load More</button>;
        } else {

            return <div class="row" key={item.id} id={item.id} onClick={() => this.openPost(item)}>
                <div class="col s12 m6">
                    <div class="card medium">
                        <div class="card-image  waves-effect waves-block waves-light">
                            <img src={item.thumbnail} alt={item.title}/>
                        </div>
                        <div class="card-content">
                            <span class="card-title">{item.title}</span>
                        </div>
                    </div>
                </div>
            </div>;
        }
    }

    elementInfiniteLoad() {
        return <div className="infinite-list-item">
            Loading...
        </div>;
    }

    renderItem() {
        var posts = this.state.posts;
        return posts.map(this.createPostRow.bind(this));
    }

    render() {
        return (
            <div class="main">
                {this.renderItem()}
            </div>
        );
    }
}

export default Posts;