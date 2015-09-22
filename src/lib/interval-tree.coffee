
SortedList = require './sorted-list'
Node       = require './node'
Point      = require './point'
Interval   = require './interval'
Util       = require './util'


###*
interval tree

@class IntervalTree
@module interval-tree2
###
class IntervalTree


    ###*
    @constructor
    @param {Number} center center of the root node
    ###
    constructor: (center) ->

        Util.assertNumber center, 'IntervalTree: center'

        ###*
        center => node

        @property {Object(Node)} nodesByCenter
        ###
        @nodesByCenter = {}


        ###*
        root node

        @property {Node} root
        ###
        @root = @createNode(center)


        ###*
        interval id => interval

        @property {Object(Interval)} intervalsById
        ###
        @intervalsById = {}


        ###*
        interval id => node

        @property {Object(Node)} nodesById
        ###
        @nodesById = {}


        ###*
        sorted list of whole point

        @property {SortedList(Point)} pointTree
        ###
        @pointTree = new SortedList('val')


        ###*
        unique id candidate of interval without id to be added next time

        @property {Number} idCandidate
        ###
        @idCandidate = 0



    ###*
    add one interval
    @param {Number} start start of the interval to create
    @param {Number} end   end of the interval to create
    @param {String|Number} [id] identifier to distinguish intervals. Automatically defiend when not set.
    @return {Interval}
    ###
    add: (start, end, id) ->

        if @intervalsById[id]?
            throw new Error('id ' + id + ' is already registered.')

        if not id?
            while @intervalsById[@idCandidate]?
                @idCandidate++
            id = @idCandidate

        interval = new Interval(start, end, id)

        @pointTree.insert new Point(interval.start, id)
        @pointTree.insert new Point(interval.end,   id)

        @intervalsById[id] = interval

        return @insert interval, @root


    ###*
    search intervals
    when only one argument is given, return intervals which contains the value
    when two arguments are given, ...

    @param {Number} val1
    @param {Number} val2
    @return {Array(Interval)} intervals
    ###
    search: (val1, val2) ->

        Util.assertNumber val1, '1st argument at IntervalTree#search()'

        if not val2?

            return @pointSearch val1, @root

        else

            Util.assertNumber val2, '2nd argument at IntervalTree#search()'

            if val2 - val1 <= 0
                throw new Error('end must be greater than start. start: ' + val1 + ', end: ' + val2)

            return @rangeSearch val1, val2


    ###*
    removes an interval of the given id

    @method remove
    @param {Number|String} id id of the interval to remove
    ###
    remove: (id) ->

        interval = @intervalsById[id]

        return if not interval?

        node = @nodesById[id]

        node.remove(interval)

        delete @nodesById[id]
        delete @intervalsById[id]


    ###*
    insert interval to the given node

    @method insert
    @private
    @param {Interval} interval
    @param {Node} node node to insert the interval
    @return {Interval} inserted interval
    ###
    insert: (interval, node) ->

        if interval.end < node.center

            node.left ?= @createNode(interval.end)

            return @insert(interval, node.left)

        if node.center < interval.start

            node.right ?= @createNode(interval.start)

            return @insert(interval, node.right)

        node.insert interval

        @nodesById[interval.id] = node

        return interval



    ###*
    create node by center

    @method createNode
    @private
    @param {Number} center
    @return {Node} node
    ###
    createNode: (center) ->

        node = new Node(center)

        @nodesByCenter[center] = node

        return node



    ###*
    search intervals at the given node

    @method pointSearch
    @private
    @param val {Number}
    @param node {Node} current node to search
    @return {Array(Interval)}
    ###
    pointSearch: (val, node) ->

        results = []

        return results if not node?

        if val < node.center

            for interval in node.starts

                break if interval.start > val

                results.push interval

            return results.concat @pointSearch(val, node.left)


        if val > node.center

            for interval in node.ends

                break if interval.end < val

                results.push interval

            return results.concat @pointSearch(val, node.right)

        # if val is node.center
        return results.concat node.starts.toArray()



    ###*
    returns intervals which covers the given start-end interval

    @method rangeSearch
    @param {Number} start start of the interval
    @param {Number} end end of the interval
    @return {Array(Interval)}
    ###
    rangeSearch: (start, end) ->

        resultsById = {}

        for interval in @pointSearch(start, @root)
            resultsById[interval.id] = interval

        for interval in @pointSearch(end, @root)
            resultsById[interval.id] = interval

        # add intervals whose point is included in the given range
        firstPos = @pointTree.firstPositionOf new Point(start)

        lastPos = @pointTree.lastPositionOf new Point(end)

        if lastPos >= 0

            for point in @pointTree.slice(firstPos, lastPos)

                resultsById[point.id] = @intervalsById[point.id]

            return (interval for id, interval of resultsById)



module.exports = IntervalTree
