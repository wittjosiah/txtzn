export let Hooks = {}

let scrollAt = () => {
  let scrollTop = document.documentElement.scrollTop || document.body.scrollTop
  let scrollHeight = document.documentElement.scrollHeight || document.body.scrollHeight
  let clientHeight = document.documentElement.clientHeight

  return scrollTop / (scrollHeight - clientHeight) * 100
}

let grandchildren = (el) => {
  return [].slice.call(el.children)
    .map((child) => [].slice.call(child.children))
    .flat()
}

Hooks.Backfeed = {
  mounted() {
    document.documentElement.scrollTop = document.documentElement.scrollTop + this.el.offsetHeight
  }
}

Hooks.FeedScroll = {
  mounted() {
    this.loading = false
   
    // Reset scroll history for the feed, feed tracks scroll position, loads
    // from closest point and the backfills the feed after initial page load
    setTimeout(() => document.documentElement.scrollTop = 0, 1)

    window.addEventListener("scroll", e => {
      clearTimeout(this.isScrolling)

      this.isScrolling = setTimeout(() => {
        const scrollTop = document.documentElement.scrollTop
        const posts = grandchildren(this.el).filter(c => c.getBoundingClientRect().y < 0)
        if (scrollTop > 0) {
          this.pushEvent("load-from", {key: posts[posts.length - 1].id})
        } else {
          this.pushEvent("load-from", {})
        }
      }, 100)

      if (!this.loading && scrollAt() > 90){
        this.loading = true
        this.pushEvent("load-more", {})
      }
    })
  },
  updated() { this.loading = false }
}