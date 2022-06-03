import java.sql.Time;
import java.util.PriorityQueue;
import java.util.Scanner;

public class Payment {
    
    public static void main(String[] args) {
        system(new Scanner(System.in));
    }

    public static void system(Scanner scanner){
        PriorityQueue<txnId> queue = new PriorityQueue<>();

        String[] firstLine = scanner.nextLine().split(" ");

        if(firstLine[0].equals("EXIT")){
            return;
        }

        long firstTime = Long.parseLong(firstLine[0]);

        int lineNumber = 0;

        queue.offer(new txnId(firstLine[1], firstTime - startingTimeFromTier(firstLine[2].charAt(0)), lineNumber));

        long previousTime = firstTime;

        while(scanner.hasNextLine()){
            String[] line = scanner.nextLine().split(" ");
            lineNumber++;

            if(line.length == 3){
                long time = Long.parseLong(line[0]);
            
                queue.offer(new txnId(line[1], time - startingTimeFromTier(line[2].charAt(0)), lineNumber));

                if(((((time / 1000) - (previousTime / 1000)) > 0) & (time % 1000 != 0)) || previousTime % 1000 == 0){
                    int toPrint = Math.min(queue.size(), 100);

                    for (int i = 0; i < toPrint; i++) {
                        System.out.print(queue.poll() + " ");
                    }

                    System.out.println();
                }

                previousTime = time;
            } else {
                if(line[0].equals("EXIT")){
                    scanner.close();
                    return;
                } else {
                    system(scanner);
                }
            }
        }
    }

    public static long startingTimeFromTier(char firstChar) {
        switch (firstChar) {
            case 'B': // Bronze
                return 0;
            case 'S': // Silver
                return 1000;
            case 'G': // Gold
                return 2000;
            case 'P': // Platinum
                return 3000;
            default: // Won't happen.
                return -1;
        }
    }

}

class txnId implements Comparable<txnId> {
    String id;
    long time;
    int insertionOrder;

    public txnId(String id, long time, int insertionOrder) {
        this.id = id;
        this.time = time;
        this.insertionOrder = insertionOrder;
    }

    @Override
    public int compareTo(txnId o) {
        int compare = Long.compare(time, o.time);
        if (compare == 0) {
            return Integer.compare(insertionOrder, o.insertionOrder);
        }
        return compare;
    }

    @Override
    public String toString() {
        return id;
    }
}
