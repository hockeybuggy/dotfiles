const ghApiComments = /gh api[^|;&]*(comments|reviews)/
const mutating = /(-X|--method)[ =]+(POST|PATCH|PUT|DELETE)|(^| )(-f|-F|--field|--raw-field|--input)[ =]/

const isCommentWrite = (command) => ghApiComments.test(command) && mutating.test(command)

export default {
  id: "ask-gh-api-comment-writes",

  async setup(ctx) {
    await ctx.permission.hook("evaluate", (event) => {
      if (event.action !== "shell") return
      if (event.effect === "deny") return
      if (event.resources.some(isCommentWrite)) {
        event.effect = "ask"
        event.message = "Mutating gh api comment/review call — confirm to proceed"
      }
    })
  },
}
