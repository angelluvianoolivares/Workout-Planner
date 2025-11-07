// social.js
// JavaScript for Social Feed Page
// Storage Keys
const CURRENT_USER_KEY = "currentUser";
const LOGS_KEY = "neurofit.logs";
const POSTS_KEY = "neurofit.social.posts";

// Get elements
const postForm = document.getElementById('postForm');
const postText = document.getElementById('postText');
const postMessage = document.getElementById('postMessage');
const feedContainer = document.getElementById('feedContainer');
const feedFilter = document.getElementById('feedFilter');
const menuToggle = document.getElementById('menuToggle');
const sidebar = document.getElementById('sidebar');
const logoutBtn = document.getElementById('logoutBtn');
const useLatestBtn = document.getElementById('useLatestBtn');
const quickShareSection = document.getElementById('quickShareSection');
const latestWorkout = document.getElementById('latestWorkout');

// CHECK IF USER IS LOGGED IN
function checkLogin() {
    const user = localStorage.getItem(CURRENT_USER_KEY);
    if (!user) {
        alert('Please log in first!');
        window.location.href = 'index.html#/login';
        return null;
    }
    return JSON.parse(user);
}

// GET DATA FROM LOCALSTORAGE
function getPosts() {
    const posts = localStorage.getItem(POSTS_KEY);
    return posts ? JSON.parse(posts) : [];
}

function savePosts(posts) {
    localStorage.setItem(POSTS_KEY, JSON.stringify(posts));
}

function getLogs() {
    const logs = localStorage.getItem(LOGS_KEY);
    return logs ? JSON.parse(logs) : [];
}

// UTILITY FUNCTIONS
function escapeHTML(str) {
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
}

function timeAgo(timestamp) {
    const now = Date.now();
    const diff = now - timestamp;
    const minutes = Math.floor(diff / 60000);
    const hours = Math.floor(diff / 3600000);
    const days = Math.floor(diff / 86400000);

    if (minutes < 1) return "Just now";
    if (minutes < 60) return `${minutes}m ago`;
    if (hours < 24) return `${hours}h ago`;
    if (days < 7) return `${days}d ago`;
    return new Date(timestamp).toLocaleDateString();
}

// SHOW LATEST WORKOUT FOR QUICK SHARE
function showLatestWorkout() {
    const logs = getLogs();
    if (logs.length > 0) {
        const latest = logs[0];
        quickShareSection.style.display = 'block';
        latestWorkout.innerHTML = `
            <strong>${escapeHTML(latest.exercise)}</strong> — 
            ${latest.sets}×${latest.reps} @ ${latest.weight} ${latest.units || 'lbs'}
        `;
        
        // When clicked, fill in the post text
        useLatestBtn.onclick = function() {
            postText.value = `Just crushed ${latest.exercise}! ${latest.sets} sets × ${latest.reps} reps @ ${latest.weight} ${latest.units || 'lbs'} 💪`;
        };
    }
}

// CREATE NEW POST
function createPost(text, user) {
    const posts = getPosts();
    
    const newPost = {
        id: Date.now() + Math.random(), // Simple unique ID
        author: user.username,
        authorEmail: user.email,
        text: text,
        timestamp: Date.now(),
        likes: 0,
        comments: []
    };
    
    posts.unshift(newPost); // Add to beginning
    savePosts(posts);
    return newPost;
}

// DELETE POST
function deletePost(postId) {
    const posts = getPosts();
    const filtered = posts.filter(p => p.id !== postId);
    savePosts(filtered);
    displayFeed();
}

// LIKE POST
function likePost(postId) {
    const posts = getPosts();
    const post = posts.find(p => p.id === postId);
    if (post) {
        post.likes = (post.likes || 0) + 1;
        savePosts(posts);
        displayFeed();
    }
}

// ADD COMMENT
function addComment(postId, commentText, user) {
    const posts = getPosts();
    const post = posts.find(p => p.id === postId);
    
    if (post) {
        if (!post.comments) post.comments = [];
        post.comments.push({
            id: Date.now(),
            author: user.username,
            text: commentText,
            timestamp: Date.now()
        });
        savePosts(posts);
        displayFeed();
    }
}

// DISPLAY FEED
function displayFeed() {
    const user = checkLogin();
    if (!user) return;
    
    let posts = getPosts();
    const filterValue = feedFilter.value;
    
    // Apply filters
    if (filterValue === 'mine') {
        posts = posts.filter(p => p.authorEmail === user.email);
    } else if (filterValue === 'today') {
        const today = new Date().toDateString();
        posts = posts.filter(p => new Date(p.timestamp).toDateString() === today);
    } else if (filterValue === 'week') {
        const weekAgo = Date.now() - (7 * 24 * 60 * 60 * 1000);
        posts = posts.filter(p => p.timestamp >= weekAgo);
    }
    
    // Show message if no posts
    if (posts.length === 0) {
        feedContainer.innerHTML = `
            <div class="card">
                <p class="helper" style="text-align: center; padding: 40px 0;">
                    No posts yet. Be the first to share! 💪
                </p>
            </div>
        `;
        return;
    }
    
    // Display posts
    feedContainer.innerHTML = posts.map(post => {
        const isOwner = post.authorEmail === user.email;
        
        return `
            <div class="card" style="margin-top: 16px;" data-post-id="${post.id}">
                <!-- Post Header -->
                <div class="row" style="margin-bottom: 12px;">
                    <div>
                        <strong style="color: var(--primary);">${escapeHTML(post.author)}</strong>
                        <small style="color: var(--muted); display: block; margin-top: 2px;">
                            ${timeAgo(post.timestamp)}
                        </small>
                    </div>
                    ${isOwner ? `
                        <button class="btn btn-outline delete-btn" style="background: var(--danger); color: white; padding: 6px 12px;">
                            Delete
                        </button>
                    ` : ''}
                </div>
                
                <!-- Post Content -->
                <p style="margin: 0 0 16px; white-space: pre-wrap; line-height: 1.5;">
                    ${escapeHTML(post.text)}
                </p>
                
                <!-- Action Buttons -->
                <div class="row" style="padding-top: 12px; border-top: 1px solid var(--border);">
                    <button class="btn btn-outline like-btn" style="padding: 6px 12px;">
                        👍 ${post.likes || 0}
                    </button>
                    <button class="btn btn-outline comment-btn" style="padding: 6px 12px;">
                        💬 ${(post.comments || []).length}
                    </button>
                </div>
                
                <!-- Comments Section (Hidden by default) -->
                <div class="comments-section" style="display: none; margin-top: 16px; padding-top: 16px; border-top: 1px solid var(--border);">
                    ${(post.comments || []).map(comment => `
                        <div style="padding: 8px; margin: 8px 0; border-left: 2px solid var(--primary);">
                            <div style="display: flex; justify-content: space-between; margin-bottom: 4px;">
                                <strong style="font-size: 0.9rem;">${escapeHTML(comment.author)}</strong>
                                <small style="color: var(--muted);">${timeAgo(comment.timestamp)}</small>
                            </div>
                            <p style="margin: 0; font-size: 0.9rem;">${escapeHTML(comment.text)}</p>
                        </div>
                    `).join('')}
                    
                    <!-- Add Comment Form -->
                    <form class="comment-form" style="margin-top: 12px;">
                        <div class="row">
                            <input type="text" class="input comment-input" placeholder="Add a comment..." style="flex: 1;" />
                            <button type="submit" class="btn btn-primary" style="padding: 8px 16px;">Post</button>
                        </div>
                    </form>
                </div>
            </div>
        `;
    }).join('');
    
    // Attach event listeners after rendering
    attachEventListeners(user);
}

// ATTACH EVENT LISTENERS TO POSTS
function attachEventListeners(user) {
    // Like buttons
    document.querySelectorAll('.like-btn').forEach(btn => {
        btn.addEventListener('click', function() {
            const postId = this.closest('[data-post-id]').dataset.postId;
            likePost(Number(postId));
        });
    });
    
    // Comment toggle buttons
    document.querySelectorAll('.comment-btn').forEach(btn => {
        btn.addEventListener('click', function() {
            const post = this.closest('[data-post-id]');
            const commentsSection = post.querySelector('.comments-section');
            commentsSection.style.display = commentsSection.style.display === 'none' ? 'block' : 'none';
        });
    });
    
    // Comment forms
    document.querySelectorAll('.comment-form').forEach(form => {
        form.addEventListener('submit', function(e) {
            e.preventDefault();
            const postId = this.closest('[data-post-id]').dataset.postId;
            const input = this.querySelector('.comment-input');
            const text = input.value.trim();
            
            if (text) {
                addComment(Number(postId), text, user);
                input.value = '';
            }
        });
    });
    
    // Delete buttons
    document.querySelectorAll('.delete-btn').forEach(btn => {
        btn.addEventListener('click', function() {
            if (confirm('Delete this post?')) {
                const postId = this.closest('[data-post-id]').dataset.postId;
                deletePost(Number(postId));
            }
        });
    });
}

// INITIALIZE PAGE
window.addEventListener('load', function() {
    const user = checkLogin();
    if (!user) return;
    
    // Show latest workout for quick share
    showLatestWorkout();
    
    // Display feed
    displayFeed();
    
    // Handle post form submission
    postForm.addEventListener('submit', function(e) {
        e.preventDefault();
        
        const text = postText.value.trim();
        if (!text) {
            postMessage.className = 'alert error';
            postMessage.textContent = 'Please write something to share!';
            return;
        }
        
        createPost(text, user);
        postText.value = '';
        postMessage.className = 'alert success';
        postMessage.textContent = 'Posted successfully! 🎉';
        
        displayFeed();
        
        setTimeout(() => {
            postMessage.textContent = '';
        }, 3000);
    });
    
    // Handle filter changes
    feedFilter.addEventListener('change', function() {
        displayFeed();
    });
    
    // Mobile menu toggle
    menuToggle.addEventListener('click', function() {
        sidebar.classList.toggle('open');
    });
    
    // Logout button
    logoutBtn.addEventListener('click', function() {
        localStorage.removeItem(CURRENT_USER_KEY);
        window.location.href = 'index.html#/login';
    });
});