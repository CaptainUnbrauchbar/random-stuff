
# WoT Gold / Bond Auszahlrechner by Florian (Born_in_Dakota13) CH3SS Elite Clan


import copy, math, time, requests
import terminaltables


def getData():

    clanInput = str(input("Insert Clan Name: "))
    rawData = requests.get("https://volknn.ru/dawn/classes/getclan.php?front=west&name={}&server=eu".format(clanInput))
    textData = rawData.text
    listData = textData.split("{")

    global goldGesamt, clanName, clanPos
    index = 0
    spielerListe = []

    pos = listData[5].find('gold') + 6
    posx = listData[5].find('users') - 3
    goldGesamt = listData[5][pos:posx]


    pos = listData[5].find('clan_name') + 12
    posx = listData[5].find('position') - 3
    clanName = listData[5][pos:posx]

    pos = listData[5].find('position') + 10
    posx = listData[5].find('points') - 2
    clanPos = listData[5][pos:posx]

    for x in range (6, len(listData)):
        #NAME EXTRACT
        pos = listData[x].find('points') - 3
        name = listData[x][8:pos]

        #POINTS EXTRACT
        pos = listData[x].find('points') + 8
        posx = listData[x].find('position') -2
        pts = listData[x][pos:posx]

        #BTTLS EXTRACT
        pos = listData[x].find('battles') + 9
        posx = listData[x].find('bt_clan') -2
        bttl = listData[x][pos:posx]

        spielerListe.append([name])
        spielerListe[index].append(int(bttl))
        spielerListe[index].append(int(pts))
        index += 1
    return spielerListe

def rechner(liste):
    ergListe = []  
    gefechteGesamt = 0

    for i in range(len(liste)):
        gefechteGesamt += liste[i][1]

    for k in range(len(liste)):
        ergListe.append([liste[k][0]])
        faktor = liste[k][1]/gefechteGesamt
        gold = float(goldGesamt) * faktor
        pts = liste[k][2]
        ergListe[k].append(round(gold))
        ergListe[k].append(pts)
    ergListe.sort(key=lambda x:x[1],reverse=True)
    ergListe.insert(0,["Name","Gold","Points"])
    print("Gold: ", goldGesamt)
    print("Clan: ", clanName)
    print("Rank: ", clanPos)
    print("\n - List sorted by Fame Points - ")


    table = terminaltables.SingleTable(ergListe)
    print(table.table)

liste = getData()
rechner(liste)