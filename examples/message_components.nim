import dimscord, asyncdispatch, strutils, options
const token {.strdefine.} = "<your bot token goes here or use -d:token=(yourtoken)>"
let discord = newDiscordClient(token)

proc messageCreate(s: Shard, m: Message) {.event(discord).} =
    let content = m.content
    if m.author.bot or not content.startsWith("$$"): return
    var row = newActionRow()
    case content.replace("$$", "").toLowerAscii():
    of "button":
        row &= newButton(
            label = "click me!",
            idOrUrl = "someUniqueID",
            emoji = Emoji(name: some "🔥")
        )
    of "menu":
        row &= newSelectMenu("someUniqueID", @[
            newMenuOption("Red", "red", emoji = Emoji(name: some "🔥")),
            newMenuOption("Green", "green"),
            newMenuOption("Blue", "blue")
        ])
    else:
      # Message doesn't match, ignore
      return

    discard await discord.api.sendMessage(
        m.channel_id,
        "hello",
        components = @[row]
    )
    let iResp = discord.waitForComponentUse("someUniqueID")
    # Wait 10 seconds for user to use a component
    if not await iResp.withTimeout(10 * 1000):
      return
    let
      i = await iResp
      data = i.data.unsafeGet()
    # Change the message depending on what the user used
    let msg = if data.componentType == SelectMenu: "You selected " & data.values[0]
              else: "You pressed the button"
    # Respond back to the interaction
    await discord.api.interactionResponseMessage(
        i.id, i.token,
        kind = irtChannelMessageWithSource,
        response = InteractionCallbackDataMessage(
            content: msg
        )
    )

proc onReady(s: Shard, r: Ready) {.event(discord).} =
    echo "Ready as: " & $r.user

# Connect to Discord and run the bot.
waitFor discord.startSession()
