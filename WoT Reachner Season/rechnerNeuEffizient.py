import terminaltables, requests, json
import time
import logging
import sys

def progressBar(current, total, barLength = 20, accountList = []):
    percent = float(current) * 100 / total
    arrow   = '█' * int(percent/100 * barLength - 1)
    spaces  = '-' * (barLength - len(arrow))

    print('Progress: [%s%s] %d %% >> %s' % (arrow, spaces, percent, accountList[current][1] + "                                                         "), end='\r')

def get(url):
    try:
        return requests.get(url,timeout=2)
    except Exception:
        return get(url)

vehicleLVL = None
clanID = None
membersCount = None
goldAmount = None
bondsAmount = None

def getData():

    global vehicleLVL, clanID, membersCount, goldAmount, bondsAmount

    clanInput = str(input("Insert clan tag: "))
    vehicleLVL = str(input("Insert Front Tier (8 or 10): "))

    goldAmount = int(input("Amount of earned Gold: "))
    bondsAmount = int(input("Amount of earned Bonds: "))

    print("\nThe process may take up to 1-2 minutes, please wait ...")
    print("\nFetching clan members ...")

    rawClanID = get("https://api.worldoftanks.eu/wgn/clans/list/?application_id=a03d55f709edee6073c41f52cbeffa99&fields=clan_id&game=wot&search={}".format(clanInput))
    rawClanID = rawClanID.text

    parsed = json.loads(rawClanID)
    clanID = parsed["data"][0]["clan_id"]

    rawData = get("https://api.worldoftanks.eu/wot/clans/info/?application_id=a03d55f709edee6073c41f52cbeffa99&fields=members_count%2Cmembers.account_id&clan_id={}".format(clanID))
    rawData = rawData.text

    parsed = json.loads(rawData)
    membersCount = parsed["data"][str(clanID)]["members_count"]
    
    accountList = []

    for i in range(0, membersCount):
        accid = parsed["data"][str(clanID)]["members"][i]["account_id"]
        accountList.append([accid])

    print("\nFetching member nicknames ... \n")

    accountIDStr = ""
    for i in range(membersCount):
        if i < membersCount-1:
            accountIDStr = accountIDStr + str(accountList[i][0]) + "%2C"
        else: 
            accountIDStr = accountIDStr + str(accountList[i][0])

    temp = get("https://api.worldoftanks.eu/wot/account/info/?application_id=a03d55f709edee6073c41f52cbeffa99&fields=nickname&account_id={}".format(accountIDStr))
    temp = temp.text

    parsed = json.loads(temp)
    
    for i in range(0, membersCount):
        name = parsed["data"][str(accountList[i][0])]["nickname"]
        accountList[i].append(name)
 
    print("Fetching member battles ... \n")

    for i in range(0, membersCount):
        accountID = str(accountList[i][0])
        temp = get("https://api.worldoftanks.eu/wot/globalmap/seasonaccountinfo/?application_id=a03d55f709edee6073c41f52cbeffa99&account_id={}&season_id=season_14&vehicle_level={}&fields=seasons.battles".format(accountID,vehicleLVL))
        temp = temp.text
        
        parsed = json.loads(temp)
        count = parsed["data"][accountID]["seasons"]["season_14"][0]["battles"]

        if count == None: 
            count = 0
        accountList[i].append(int(count))

        progressBar(i,membersCount,50,accountList)

    return accountList

def calculate(liste):
    print("\nSorting after battle count ...\n")
    
    temp = get("https://api.worldoftanks.eu/wgn/clans/info/?application_id=a03d55f709edee6073c41f52cbeffa99&clan_id={}&fields=name%2C+tag".format(clanID))
    temp = temp.text
    parsed = json.loads(temp)

    clanTag = parsed["data"][str(clanID)]["tag"]
    clanName = clanTag + ": " + parsed["data"][str(clanID)]["name"]

    temp = get("https://api.worldoftanks.eu/wot/globalmap/claninfo/?application_id=a1671ac4c789dc5fe2a8253686c2f756&fields=ratings.elo_10%2Cratings.elo_8%2Cstatistics.captures%2Cstatistics.provinces_count&clan_id={}".format(clanID))
    temp = temp.text
    parsed = json.loads(temp)

    clanELO = "ELO 10: " + str(parsed["data"][str(clanID)]["ratings"]["elo_10"]) + ", ELO 8: " + str(parsed["data"][str(clanID)]["ratings"]["elo_8"])
    clanStats =  "Provinces captured: " + str(parsed["data"][str(clanID)]["statistics"]["captures"]) + ", Province Count: " + str(parsed["data"][str(clanID)]["statistics"]["provinces_count"])

    print(clanName)
    print(clanELO)
    print(clanStats)

    gefechteGesamt = 0
    for i in range(len(liste)):
        gefechteGesamt += liste[i][2]
    for k in range(len(liste)):
        faktor = liste[k][2]/gefechteGesamt
        gold = int(round(goldAmount * faktor))
        bonds = int(round(bondsAmount * faktor))
        liste[k].append(gold)
        liste[k].append(bonds)

    print("\n{}, Member count: {}".format(clanName, membersCount))

    liste.sort(key=lambda x:x[2],reverse=True)
    liste.insert(0,["AccID","Nickname","Battles","Gold","Bonds"])

    goldCheck = 0
    bondsCheck = 0

    for i in range(1,len(liste)):
        goldCheck += liste[i][3]
        bondsCheck += liste[i][4]

    table = terminaltables.SingleTable(liste)

    print(table.table)
    print("Gold Amount: {} ({}), Bonds Amount: {} ({})".format(goldAmount, goldCheck, bondsAmount, bondsCheck))

liste = getData()
calculate(liste)
str(input("\n Fertig ..."))