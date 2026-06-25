import sqlite3
import os

def view_db_data():
    db_path = "greennest.db"
    if not os.path.exists(db_path):
        print(f"Error: Database file '{db_path}' does not exist yet. Please start the server to create it.")
        return

    print("=== GreenNest SQLite Database Inspector ===")
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # 1. Fetch Users
    print("\n--- USERS TABLE (users) ---")
    cursor.execute("SELECT user_id, name, email, role, password FROM users")
    users = cursor.fetchall()
    print(f"{'ID':<5} | {'Name':<15} | {'Email':<25} | {'Role':<8} | {'Password':<10}")
    print("-" * 75)
    for u in users:
        print(f"{u[0]:<5} | {u[1]:<15} | {u[2]:<25} | {u[3]:<8} | {u[4]:<10}")

    # 2. Fetch Plants
    print("\n--- PLANTS CATALOG (plants) ---")
    cursor.execute("SELECT plant_id, name, category, price, stock FROM plants")
    plants = cursor.fetchall()
    print(f"{'ID':<5} | {'Name':<22} | {'Category':<12} | {'Price':<10} | {'Stock':<6}")
    print("-" * 65)
    for p in plants:
        print(f"{p[0]:<5} | {p[1]:<22} | {p[2]:<12} | {f'Rs.{p[3]}':<10} | {p[4]:<6}")

    # 3. Fetch Orders
    print("\n--- CUSTOMER ORDERS (orders) ---")
    cursor.execute("SELECT order_id, user_id, total_amount, status, order_date FROM orders")
    orders = cursor.fetchall()
    if not orders:
        print("No orders placed yet.")
    else:
        print(f"{'Order ID':<10} | {'User ID':<8} | {'Total Amount':<15} | {'Status':<12} | {'Date':<20}")
        print("-" * 75)
        for o in orders:
            print(f"{o[0]:<10} | {o[1]:<8} | {f'Rs.{o[2]}':<15} | {o[3]:<12} | {o[4][:19]:<20}")

    # 4. Fetch Gifts
    print("\n--- SCHEDULED GIFTS (gifts) ---")
    cursor.execute("SELECT gift_id, sender_id, recipient_name, recipient_mobile, delivery_date, status FROM gifts")
    gifts = cursor.fetchall()
    if not gifts:
        print("No gift deliveries scheduled yet.")
    else:
        print(f"{'Gift ID':<8} | {'Sender ID':<10} | {'Recipient':<15} | {'Mobile':<12} | {'Delivery Date':<15} | {'Status':<10}")
        print("-" * 80)
        for g in gifts:
            print(f"{g[0]:<8} | {g[1]:<10} | {g[2]:<15} | {g[3]:<12} | {g[4]:<15} | {g[5]:<10}")

    # 5. Fetch PlantCards
    print("\n--- SAVED USER PLANT CARDS (plant_cards) ---")
    cursor.execute("SELECT plant_card_id, user_id, nickname, species, location FROM plant_cards")
    plant_cards = cursor.fetchall()
    if not plant_cards:
        print("No saved plant cards (gardens) yet.")
    else:
        print(f"{'Card ID':<8} | {'User ID':<8} | {'Nickname':<15} | {'Species':<20} | {'Location':<15}")
        print("-" * 70)
        for pc in plant_cards:
            print(f"{pc[0]:<8} | {pc[1]:<8} | {pc[2]:<15} | {pc[3]:<20} | {pc[4]:<15}")

    conn.close()

if __name__ == "__main__":
    view_db_data()
