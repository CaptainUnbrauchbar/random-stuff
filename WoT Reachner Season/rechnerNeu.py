
import copy, math, time, requests
import terminaltables

def getData():
    global vehicleLVL, clanID, membersCount 
    clanInput = str(input("Insert clan tag: "))
    vehicleLVL = str(input("Insert Front Tier (8 or 10): "))
    print("\nThe process may take up to 1-2 minutes, please wait ...")
    print("\nFetching clan members ...")

    rawClanID = requests.get("https://api.worldoftanks.eu/wgn/clans/list/?application_id=a1671ac4c789dc5fe2a8253686c2f756&fields=clan_id&game=wot&search={}".format(clanInput))
    rawClanID = rawClanID.text

    pos = rawClanID.find('clan_id') + 9
    clanID = rawClanID[pos:pos+9]

    rawData = requests.get("https://api.worldoftanks.eu/wot/clans/info/?application_id=a1671ac4c789dc5fe2a8253686c2f756&fields=members_count%2Cmembers.account_id&clan_id={}".format(clanID))
    rawData = rawData.text

    pos = rawData.find('members_count') + 15
    posx = rawData.find('\"members\":') - 1
    membersCount = int(rawData[pos:posx])
    rawData = rawData.split("account_id")
    
    accountList = []

    for i in range(1, len(rawData)):
        temp = rawData[i]
        temp = temp[2:11]
        accountList.append([temp])

    lenA = len(accountList)
    print("\nFetching member nicknames ... \n")
    for i in range(lenA):
        accountID = accountList[i]
        temp = requests.get("https://api.worldoftanks.eu/wot/account/info/?application_id=a1671ac4c789dc5fe2a8253686c2f756&fields=nickname&account_id={}".format(accountID[0]))
        temp = temp.text
        pos = temp.find('nickname') + 11
        posx = temp.find('}}}') -1

        if i == membersCount // 4: print("- 25% -")
        if i == membersCount // 2: print("- 50% -       WG Servers sloooooooooow")
        if i == int(membersCount // 1.5): print("- 75% -")
        if i == membersCount - 1: print("- 100% -")

        print("> Fetching Nickname of {} ".format(accountID))
        temp = temp[pos:posx]
        accountList[i].append(temp)
    print("\nFetching member battles ... \n")
    for i in range(lenA):
        accountID = accountList[i][0]
        temp = requests.get("https://api.worldoftanks.eu/wot/globalmap/seasonaccountinfo/?application_id=a1671ac4c789dc5fe2a8253686c2f756&season_id=season_14&fields=seasons.battles&vehicle_level={}&account_id={}".format(vehicleLVL,accountID[0]))
        temp = temp.text
        pos = temp.find('battles') + 9
        posx = temp.find('}]}}}')

        if i == membersCount // 4: print("- 25% -")
        if i == membersCount // 2: print("- 50% -       WG Servers sloooooooooooooooow")
        if i == int(membersCount // 1.5): print("- 75% -")
        if i == membersCount - 1: print("- 100% -")
        print("> Fetching Nickname of {} ".format(accountList[i][1]))
        temp = temp[pos:posx]
        if temp == "null": temp = 0
        accountList[i].append(int(temp))

    return accountList

def rechner(liste):
    print("\nSorting after battle count ...")
    
    clanName = requests.get("https://api.worldoftanks.eu/wgn/clans/info/?application_id=a1671ac4c789dc5fe2a8253686c2f756&clan_id={}&fields=name%2C+tag".format(clanID))
    clanName = clanName.text
    pos = clanName.find('tag') + 6
    posx = clanName.find('name')
    clanTag = clanName[pos:posx-3]
    pos = clanName.find('}}}') - 1
    clanName = clanName[posx+7:pos]
    clanName = clanTag + ": " + clanName
    print("\n{}, Member count: {}".format(clanName, membersCount))

    liste.sort(key=lambda x:x[2],reverse=True)
    liste.insert(0,["AccID","Nickname","Battles"])

    table = terminaltables.SingleTable(liste)
    print(table.table)

liste = getData()
rechner(liste)
end = str(input("\n Fertig ..."))