export let Hooks = {}

let scrollAt = () => {
  let scrollTop = document.documentElement.scrollTop || document.body.scrollTop
  let scrollHeight = document.documentElement.scrollHeight || document.body.scrollHeight
  let clientHeight = document.documentElement.clientHeight

  return scrollTop / (scrollHeight - clientHeight) * 100
}

Hooks.InfiniteScroll = {
  mounted(){
    this.pending = false
    window.addEventListener("scroll", e => {
      if (!this.pending && scrollAt() > 90){
        this.pending = true
        this.pushEvent("load-more", {})
      }
    })
  },
  updated(){ this.pending = false }
}