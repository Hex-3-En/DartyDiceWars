part of DartyDiceWars;

class DiceController {
  final view = new DiceView();
  DiceGame game;
  XmlNode level;
  String last = "";

  DiceController() {
    view.startButton.onClick.listen((_) {
      if (level == null) {
        view.startButton.style.display = "none";
        startGame(1);
      }
    });

    view.arena.onMouseLeave.listen((ev) {
      view.showHover("");
    });

    view.arena.onMouseEnter.listen((ev) {
      if (game.currentPlayer.id == "human") {
        querySelectorAll('.hex').onMouseOver.listen((_) {
          if (_.currentTarget.classes.contains("selected")) {
            view.showHover("");
          } else {
            view.showHover(_.currentTarget.getAttribute("parent"));
          }
        });
      }
    });

    view.arena.onMouseEnter.listen((ev) {
      querySelectorAll('.hex').onClick.listen((_) {
        if (last != _.currentTarget.id) {
          if (!_.currentTarget.classes.contains('.corner-1') &&
              !_.currentTarget.classes.contains('.corner-2')) {
            if (game != null && game.currentPlayer.id == "human") {
              //&&
              String parent = _.currentTarget.getAttribute("parent");
              String owner = _.currentTarget.getAttribute("owner");
              last = _.currentTarget.id;
              //INSERT STUFF YOU DO WITH SELECTED 1st and 2nd HERE

              //TO BE COPYPASTED INTO ALL THREE CASES
              print(game._arena.territories[parent].dice);
              if (game.firstTerritory == null &&
                  owner == "human" &&
                  game._arena.territories[parent].dice > 1) {

                //selectTerritory as first one
                game.firstTerritory = game._arena.territories[parent];
                view.markTerritory(parent);
              } else if (game.firstTerritory != null &&
                  parent == game.firstTerritory.id) {
                //if there is a territory selected and the new one is the same
                game.firstTerritory = null;
                view.markTerritory(parent);
              } else if (game.firstTerritory != null &&
                  game.secondTerritory == null &&
                  game.firstTerritory.neighbours.keys.contains(parent) &&
                  owner != "human" &&
                  owner != "whitefield") {
                game.secondTerritory = game._arena.territories[parent];
                view.markTerritory(parent);
              }
              if (game.firstTerritory != null && game.secondTerritory != null) {
                String attacker = game.firstTerritory.ownerRef.id;
                String defender = game.secondTerritory.ownerRef.id;
                Player attackedPlayer = game.secondTerritory.ownerRef;
                List<List<int>> attack =
                    game.firstTerritory.attackTerritory(game.secondTerritory);

                //   new Timer(new Duration(milliseconds: 1000), () => view.displayAttack(attack, attacker, defender));
                view.displayAttack(attack, attacker, defender);
//save all the content that is needed for the viewupdate so that it can get updated after the given delay
                String center1 = "ID" +
                    game._arena.territories[game.firstTerritory.id].x
                        .toString() +
                    "_" +
                    game._arena.territories[game.firstTerritory.id].y
                        .toString();
                String center2 = "ID" +
                    game._arena.territories[game.secondTerritory.id].x
                        .toString() +
                    "_" +
                    game._arena.territories[game.secondTerritory.id].y
                        .toString();
                List<String> tiles1 =
                    game._arena.territories[game.firstTerritory.id].tiles;
                List<String> tiles2 =
                    game._arena.territories[game.secondTerritory.id].tiles;
                int dice1 =
                    game._arena.territories[game.firstTerritory.id].dice;
                int dice2 =
                    game._arena.territories[game.secondTerritory.id].dice;
                String owner1 =
                    game._arena.territories[game.firstTerritory.id].ownerRef.id;
                String owner2 = game._arena.territories[
                    game.secondTerritory.id].ownerRef.id;

                new Timer(new Duration(milliseconds: 1000), () => view
                    .updateAfterAttack(center1, center2, tiles1, tiles2, dice1,
                        dice2, owner1, owner2));
              
                if (attackedPlayer.territories.length == 0) {
                           print(attackedPlayer.id + " WAS DEFEATED. DAMN SON.");
                           game.players.remove(attackedPlayer);
                           game.firstTerritory = null;
                                             game.secondTerritory = null;
                                             last = "";
                                             this.nextTurn();
                         }
        

                game.firstTerritory = null;
                game.secondTerritory = null;
                parent = "";
                new Timer(new Duration(milliseconds: 1000),
                    () => view.clearFooter(game.currentPlayer.id.toString()));

                if (!(game.players.length > 2)) {
                  this.nextTurn();
                }
              }
            }
          }
        }
        //COPYPASTE ALL OF THE ABOVE
      });
    });

    view.endTurn.onClick.listen((_) {
      if (game != null) {
        if (game.firstTerritory != null) {
          view.markTerritory(game.firstTerritory.id);
        }
        game.firstTerritory = null;
        game.secondTerritory = null;
        last = "";
        this.nextTurn();
      }
    });
  }

  startGame(int levelnr) async {
    await this.loadLevelData(levelnr);
    game = new DiceGame(60, 32, level);

    view.initializeViewField(game);
    view.updateFieldWithTerritories(game);
    print("First Player: " + game.currentPlayer.id.toString());
    if (game.currentPlayer.id != "human") {
      this.onTurn();
    }
  }

  //gets the next player and
  nextTurn() {
    if (!(game.players.length > 2)) {
      print("CURRENT GAME OVER TOO HARD M8");
      int nextLevel = (int.parse(game.level.attributes[0].value)) + 1;
      game = null;
      startGame(nextLevel);
      return;
    }
    List<Territory> toUpdate = game.currentPlayer.territories;
    //CLEAR FOOTER
    game.nextPlayer();
    view.updateSelectedTerritories(toUpdate);
    //resupply n stuff, ALSO ASSIGN NEW CURRENT PLAYER
    view.displayPlayer(game.currentPlayer.id.toString());
    print("Next Player: " + game.currentPlayer.id.toString());
    if (game.currentPlayer.id != "human") {
      this.onTurn();
    }
  }

  onTurn() {
    int waitfor = 0;
    bool turn = true;
    while (turn) {
      if (game.currentPlayer.id == "whitefield") {
        turn = false;
      } else if (game.currentPlayer.id != "human") {
        List<Territory> actors = game.currentPlayer.turn();
        if (actors.length == 0) {
          turn = false;
        } else {
          String defender = actors[1].ownerRef.id;
          Player attackedPlayer = actors[1].ownerRef;
          List<List<int>> attack = actors[0].attackTerritory(actors[1]);
          new Timer(new Duration(milliseconds: 300 + (waitfor * 2000)),
              () => view.markAIAttack(actors[0].id));
          new Timer(new Duration(milliseconds: 500 + (waitfor * 2000)),
              () => view.markAIAttack(actors[1].id));
          new Timer(new Duration(milliseconds: 1000 + (waitfor * 2000)), () =>
              view.displayAttack(attack, actors[0].ownerRef.id, defender));

          //save all the content that is needed for the viewupdate so that it can get updated after the given delay
          String center1 = "ID" +
              game._arena.territories[actors[0].id].x.toString() +
              "_" +
              game._arena.territories[actors[0].id].y.toString();
          String center2 = "ID" +
              game._arena.territories[actors[1].id].x.toString() +
              "_" +
              game._arena.territories[actors[1].id].y.toString();
          List<String> tiles1 = game._arena.territories[actors[0].id].tiles;
          List<String> tiles2 = game._arena.territories[actors[1].id].tiles;
          int dice1 = game._arena.territories[actors[0].id].dice;
          int dice2 = game._arena.territories[actors[1].id].dice;
          String owner1 = game._arena.territories[actors[0].id].ownerRef.id;
          String owner2 = game._arena.territories[actors[1].id].ownerRef.id;

          new Timer(new Duration(milliseconds: 1000 + (waitfor * 2000)),
              () => view.updateAfterAttack(center1, center2, tiles1, tiles2,
                  dice1, dice2, owner1, owner2));
          waitfor++;
          
          
          if (attackedPlayer.territories.length == 0) {
            print(attackedPlayer.id + " WAS DEFEATED. DAMN SON.");
            game.players.remove(attackedPlayer);
          }

          if (!(game.players.length > 2)) {
            turn = false;
          }
        }
      }
      //new Timer(new Duration(milliseconds: 100), () => view.clearFooter(game.currentPlayer.id.toString()));
    }
    if (game.currentPlayer.id != "whitefield") {
      new Timer(new Duration(milliseconds: 1000 + (waitfor * 2000)),
          () => this.nextTurn());
    } else this.nextTurn();
  }

  loadLevelData(int levelnr) async {
    Future<XmlNode> ret = null;
    try {
      dynamic file = await HttpRequest.getString('levels.xml');
      var levels = parse(file);
      print(file);
      for (XmlNode x in levels.firstChild.children) {
        if (x.attributes[0].value == levelnr.toString()) {
          level = x;
        }
      }
    } catch (e) {
      print("How did you even get here?! oh also: " + e.toString());
    }
  }
}
